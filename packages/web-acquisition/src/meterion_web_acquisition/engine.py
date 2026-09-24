from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping, Protocol


@dataclass(frozen=True)
class EngineRequest:
    url: str
    mode: str
    timeout_ms: int = 30_000
    wait_ms: int = 0
    network_idle: bool = False
    disable_resources: bool = False
    adaptive: bool = False
    capture_xhr_pattern: str | None = None
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class EngineResponse:
    body: bytes
    status: int | None
    final_url: str
    extraction_body: bytes | None = None
    metadata: Mapping[str, Any] = field(default_factory=dict)

    @property
    def content_for_extraction(self) -> bytes:
        return self.extraction_body if self.extraction_body is not None else self.body


class CollectionEngine(Protocol):
    name: str

    def collect(self, request: EngineRequest) -> EngineResponse: ...
