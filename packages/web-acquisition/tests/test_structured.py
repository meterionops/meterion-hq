import pytest

from meterion_web_acquisition import extract_wordpress_rendered_content


def test_extracts_wordpress_rendered_html():
    result = extract_wordpress_rendered_content(
        b'{"id": 10, "content": {"rendered": "<h2>Menu</h2><p>Soup 12.90</p>"}}'
    )
    assert result.body == b"<h2>Menu</h2><p>Soup 12.90</p>"
    assert result.extractor_id == "wordpress_content_rendered"
    assert result.extractor_version == "v1"
    assert result.content_type.startswith("text/html")


def test_fails_closed_on_empty_wordpress_content():
    with pytest.raises(ValueError, match="missing_wordpress_rendered_content"):
        extract_wordpress_rendered_content(
            b'{"id": 10, "content": {"rendered": ""}}'
        )


def test_fails_closed_on_non_json():
    with pytest.raises(ValueError, match="invalid_wordpress_json"):
        extract_wordpress_rendered_content(b"<html>not json</html>")
