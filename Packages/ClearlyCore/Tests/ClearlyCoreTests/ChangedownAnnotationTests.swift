import XCTest
@testable import ClearlyCore

final class ChangedownAnnotationTests: XCTestCase {
    func testParserExtractsFootnoteMetadataAndEntries() {
        let markdown = """
        Body.

        [^cn-4]: @avi | 2026-04-27 | comment | proposed
            @avi 2026-04-27: Tie this to faster review cycles.
            @sam 2026-04-27: Agreed.
        """

        let footnotes = ChangedownAnnotationParser.parseFootnotes(in: markdown)
        let footnote = footnotes["cn-4"]

        XCTAssertEqual(footnote?.author, "@avi")
        XCTAssertEqual(footnote?.date, "2026-04-27")
        XCTAssertEqual(footnote?.kind, "comment")
        XCTAssertEqual(footnote?.status, "proposed")
        XCTAssertEqual(footnote?.entries.count, 2)
        XCTAssertEqual(footnote?.entries.first?.text, "Tie this to faster review cycles.")
        XCTAssertEqual(footnote?.entries.last?.author, "@sam")
    }

    func testProjectionTreatsFootnoteBackedAnnotationAsFirstClassSyntax() {
        let markdown = """
        This release introduces a {==lighter preview reading mode==}[^cn-1].

        [^cn-1]: @avi | 2026-04-27 | comment | proposed
            @avi 2026-04-27: Phrase this more concretely.
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertTrue(result.markdown.contains(#"<span class="cd-annotation" data-change-id="cn-1""#))
        XCTAssertTrue(result.markdown.contains("lighter preview reading mode"))
        XCTAssertTrue(result.markdown.contains(#"data-comment="Phrase this more concretely.""#))
        XCTAssertFalse(result.markdown.contains("{=="))
        XCTAssertFalse(result.markdown.contains("[^cn-1]:"))
        XCTAssertNil(result.annotations["cn-1"]?.inlineComment)
    }

    func testProjectionReadsInlineCommentAnnotationButPrefersFootnoteSummary() {
        let markdown = """
        This release introduces a {==lighter preview reading mode==}{>> Legacy inline note. <<}[^cn-1].

        [^cn-1]: @avi | 2026-04-27 | comment | proposed
            @avi 2026-04-27: Canonical footnote note.
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertTrue(result.markdown.contains(#"<span class="cd-annotation" data-change-id="cn-1""#))
        XCTAssertTrue(result.markdown.contains("lighter preview reading mode"))
        XCTAssertTrue(result.markdown.contains(#"data-comment="Canonical footnote note.""#))
        XCTAssertFalse(result.markdown.contains("Legacy inline note"))
        XCTAssertFalse(result.markdown.contains("{=="))
        XCTAssertFalse(result.markdown.contains("{>>"))
        XCTAssertFalse(result.markdown.contains("[^cn-1]:"))
        XCTAssertEqual(result.annotations["cn-1"]?.inlineComment, "Legacy inline note.")
    }

    func testProjectionFallsBackToInlineCommentWhenFootnoteHasNoSummary() {
        let markdown = """
        Annotated {==text==}{>> Inline fallback. <<}[^cn-1].

        [^cn-1]: @avi | 2026-04-27 | comment | proposed
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertTrue(result.markdown.contains(#"data-comment="Inline fallback.""#))
    }

    func testProjectionUsesFootnoteSummaryForHighlightOnlyAnnotation() {
        let markdown = """
        Support docs recommend Clearly for {==reviewing markdown before publishing==}[^cn-3].

        [^cn-3]: @avi | 2026-04-27 | highlight | proposed
            @avi 2026-04-27: This wording is good.
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertTrue(result.markdown.contains(#"data-change-id="cn-3""#))
        XCTAssertTrue(result.markdown.contains(#"data-comment="This wording is good.""#))
        XCTAssertFalse(result.markdown.contains("[^cn-3]:"))
        XCTAssertEqual(result.annotations["cn-3"]?.footnote?.kind, "highlight")
    }

    func testProjectionKeepsOrdinaryFootnotes() {
        let markdown = """
        Annotated {==text==}{>> note <<}[^cn-1] and ordinary footnote.[^1]

        [^cn-1]: @avi | 2026-04-27 | comment | proposed
            @avi 2026-04-27: note

        [^1]: Ordinary markdown footnote.
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertFalse(result.markdown.contains("[^cn-1]:"))
        XCTAssertTrue(result.markdown.contains("[^1]: Ordinary markdown footnote."))
    }

    func testProjectionEscapesHTMLInTextAndAttributes() {
        let markdown = """
        Annotated {==<unsafe> & text==}{>> Quote "this" & that <<}[^cn-1].
        """

        let result = ChangedownAnnotationProjection.project(markdown)

        XCTAssertTrue(result.markdown.contains("&lt;unsafe&gt; &amp; text"))
        XCTAssertTrue(result.markdown.contains("Quote &quot;this&quot; &amp; that"))
    }
}
