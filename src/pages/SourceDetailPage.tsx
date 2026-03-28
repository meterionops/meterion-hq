import { ExecutionStatusCard } from "../components/source-detail/ExecutionStatusCard";
import { mockExecutionSurface } from "../dev/mockExecutionSurface";

const USE_MOCK_EXECUTION = false;

const execution = USE_MOCK_EXECUTION ? mockExecutionSurface : null;
<ExecutionStatusCard execution={execution} />
