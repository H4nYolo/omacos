// omacos — OCR helper for omacos-capture text (Apple Vision). Compiled once to ~/.cache/omacos/omacos-ocr.
import Foundation
import Vision
import AppKit
let args = CommandLine.arguments
guard args.count > 1, let img = NSImage(contentsOfFile: args[1]), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { FileHandle.standardError.write("usage: omacos-ocr <image>\n".data(using: .utf8)!); exit(1) }
let req = VNRecognizeTextRequest { r, _ in
  for o in (r.results as? [VNRecognizedTextObservation]) ?? [] { if let t = o.topCandidates(1).first { print(t.string) } }
}
req.recognitionLevel = .accurate
req.usesLanguageCorrection = true
req.recognitionLanguages = ["de-DE", "en-US"]
try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
