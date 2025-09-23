import Foundation
import PDFKit
import UIKit
import CoreText

final class ExportService {
    private let metrics: MetricsReporter
    private let fileManager = FileManager.default

    init(metrics: MetricsReporter) {
        self.metrics = metrics
    }

    @discardableResult
    func export(sop: SOP, format: ExportFormat, includeWatermark: Bool) async throws -> URL {
        await MainActor.run {
            metrics.track(event: .exportClicked(format: format))
        }

        let url: URL
        switch format {
        case .pdf:
            url = try exportPDF(sop: sop, isPro: includeWatermark == false)
        case .docx:
            url = try exportDOCX(sop: sop)
        case .markdown:
            let content = exportMarkdown(sop: sop)
            url = try write(content: content, fileName: "\(sop.id).md")
        }

        await MainActor.run {
            metrics.track(event: .exportSuccess(format: format))
        }
        return url
    }

    func exportPDF(sop: SOP, isPro: Bool) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let textRect = pageRect.insetBy(dx: 40, dy: 40)
        let attributed = makeAttributedDocument(for: sop)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let ranges = paginate(framesetter: framesetter, textLength: attributed.length, textRect: textRect)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            for (pageIndex, range) in ranges.enumerated() {
                context.beginPage()
                draw(attributed: attributed, framesetter: framesetter, range: range, in: textRect, context: context.cgContext)
                if isPro == false {
                    drawWatermark(on: context.cgContext, in: pageRect)
                }
                drawFooter(on: context.cgContext, in: pageRect, pageNumber: pageIndex + 1, totalPages: ranges.count, isPro: isPro)
            }
        }

        return try write(data: data, fileName: "\(sop.id).pdf")
    }

    func exportMarkdown(sop: SOP) -> String {
        var lines: [String] = []
        lines.append("# \(sop.title)")
        lines.append("")
        lines.append("## Summary")
        lines.append(sop.summary)
        lines.append("")
        if sop.tools.isEmpty == false {
            lines.append("## Tools Needed")
            sop.tools.forEach { tool in
                lines.append("- \(tool)")
            }
            lines.append("")
        }
        lines.append("## Steps")
        sop.steps.forEach { step in
            lines.append("\(step.number). \(step.instruction)")
            if let notes = step.notes {
                lines.append("> Notes: \(notes)")
            }
            if let minutes = step.estMinutes {
                lines.append("> Estimated Minutes: \(minutes)")
            }
        }
        return lines.joined(separator: "\n")
    }

    func exportDOCX(sop: SOP) throws -> URL {
        let attributed = makeAttributedDocument(for: sop)
        let range = NSRange(location: 0, length: attributed.length)
        let data = try attributed.data(
            from: range,
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.officeOpenXML,
                .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
            ]
        )
        return try write(data: data, fileName: "\(sop.id).docx")
    }

    // MARK: - PDF Helpers

    private func paginate(framesetter: CTFramesetter, textLength: Int, textRect: CGRect) -> [CFRange] {
        var ranges: [CFRange] = []
        var currentIndex: CFIndex = 0

        while currentIndex < textLength {
            let path = CGMutablePath()
            path.addRect(textRect)
            let range = CFRange(location: currentIndex, length: 0)
            let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
            let visible = CTFrameGetVisibleStringRange(frame)
            if visible.length == 0 {
                break
            }
            ranges.append(CFRange(location: currentIndex, length: visible.length))
            currentIndex += visible.length
        }

        if ranges.isEmpty {
            ranges.append(CFRange(location: 0, length: textLength))
        }

        return ranges
    }

    private func draw(attributed: NSAttributedString, framesetter: CTFramesetter, range: CFRange, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)

        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: CGSize(width: rect.width, height: rect.height)))
        let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
        CTFrameDraw(frame, context)

        context.restoreGState()
    }

    private func drawWatermark(on context: CGContext, in pageRect: CGRect) {
        let watermark = NSLocalizedString(Brand.watermarkFree, comment: "PDF watermark")
        context.saveGState()
        context.translateBy(x: pageRect.midX, y: pageRect.midY)
        context.rotate(by: -.pi / 4)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.systemGray.withAlphaComponent(0.2)
        ]
        let size = watermark.size(withAttributes: attributes)
        let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
        watermark.draw(at: origin, withAttributes: attributes)
        context.restoreGState()
    }

    private func drawFooter(on context: CGContext, in pageRect: CGRect, pageNumber: Int, totalPages: Int, isPro: Bool) {
        let footer = "Page \(pageNumber) of \(totalPages)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .footnote),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let size = footer.size(withAttributes: attributes)
        let origin = CGPoint(x: pageRect.maxX - size.width - 40, y: pageRect.minY + 24)
        footer.draw(at: origin, withAttributes: attributes)
    }

    // MARK: - Attribution Builders

    private func makeAttributedDocument(for sop: SOP) -> NSMutableAttributedString {
        let document = NSMutableAttributedString()
        let isRTL = isRightToLeft(sop: sop)

        let headingStyle = NSMutableParagraphStyle()
        headingStyle.paragraphSpacing = 8
        headingStyle.baseWritingDirection = isRTL ? .rightToLeft : .leftToRight
        headingStyle.alignment = isRTL ? .right : .left

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineBreakMode = .byWordWrapping
        bodyStyle.paragraphSpacing = 6
        bodyStyle.baseWritingDirection = headingStyle.baseWritingDirection
        bodyStyle.alignment = headingStyle.alignment

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .title1),
            .paragraphStyle: headingStyle
        ]

        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .paragraphStyle: headingStyle
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: bodyStyle
        ]

        document.append(NSAttributedString(string: "\(sop.title)\n", attributes: titleAttributes))
        document.append(NSAttributedString(string: "Summary\n", attributes: sectionAttributes))
        document.append(NSAttributedString(string: "\(sop.summary)\n\n", attributes: bodyAttributes))

        if sop.tools.isEmpty == false {
            document.append(NSAttributedString(string: "Tools Needed\n", attributes: sectionAttributes))
            document.append(NSAttributedString(string: sop.tools.joined(separator: ", ") + "\n\n", attributes: bodyAttributes))
        }

        document.append(NSAttributedString(string: "Steps\n", attributes: sectionAttributes))
        sop.steps.forEach { step in
            var line = "\(step.number). \(step.instruction)"
            if let minutes = step.estMinutes {
                line += " (\(minutes)m)"
            }
            document.append(NSAttributedString(string: line + "\n", attributes: bodyAttributes))
            if let notes = step.notes {
                document.append(NSAttributedString(string: "   Notes: \(notes)\n", attributes: bodyAttributes))
            }
        }

        return document
    }

    private func isRightToLeft(sop: SOP) -> Bool {
        let combined = [sop.title, sop.summary] + sop.steps.map { $0.instruction + (" " + ($0.notes ?? "")) }
        let scalars = combined.joined().unicodeScalars
        let rtlRanges: [ClosedRange<UInt32>] = [0x0590...0x08FF]
        return scalars.contains { scalar in
            rtlRanges.contains { $0.contains(UInt32(scalar.value)) }
        }
    }

    // MARK: - File Helpers

    private func write(content: String, fileName: String) throws -> URL {
        guard let data = content.data(using: .utf8) else {
            throw ExportError.writeFailed
        }
        return try write(data: data, fileName: fileName)
    }

    private func write(data: Data, fileName: String) throws -> URL {
        let url = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw ExportError.writeFailed
        }
    }
}

enum ExportError: Error {
    case writeFailed
}
