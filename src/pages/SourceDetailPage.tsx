import { ExecutionStatusCard } from "../components/source-detail/ExecutionStatusCard";
import { mockExecutionSurface } from "../dev/mockExecutionSurface";

const USE_MOCK_EXECUTION = false;

const execution = USE_MOCK_EXECUTION ? mockExecutionSurface : null;
<ExecutionStatusCard execution={execution} />
import { DecisionHistoryCard } from "../components/source-detail/DecisionHistoryCard";
import { ExecutionHistoryCard } from "../components/source-detail/ExecutionHistoryCard";
import { CaseTimelineCard } from "../components/source-detail/CaseTimelineCard";

import { mockDecisionHistorySurface } from "../dev/mockDecisionHistorySurface";
import { mockExecutionHistorySurface } from "../dev/mockExecutionHistorySurface";
import { mockCaseTimelineSurface } from "../dev/mockCaseTimelineSurface";
