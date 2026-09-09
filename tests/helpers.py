import hashlib


def mediawiki_response_document(
    content: str = "return {answer=42}",
    *,
    title: str = "Module:PetData/Core",
) -> dict:
    encoded = content.encode("utf-8")
    return {
        "batchcomplete": True,
        "query": {
            "pages": [
                {
                    "pageid": 10,
                    "title": title,
                    "revisions": [
                        {
                            "revid": 20,
                            "timestamp": "2026-09-09T00:00:00Z",
                            "size": len(encoded),
                            "sha1": hashlib.sha1(encoded).hexdigest(),
                            "slots": {
                                "main": {
                                    "contentmodel": "Scribunto",
                                    "content": content,
                                }
                            },
                        }
                    ],
                }
            ]
        },
    }
