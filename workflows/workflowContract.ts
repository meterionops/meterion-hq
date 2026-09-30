/** Workflow metadata narrows existing execution authority; it never grants it. */
export interface WorkflowContract {
  schema: 'meterion.workflow.v1';
  id: string;
  version: number;
  trigger: string;
  objective: string;
  owner: { role: string; authority: 'read_only' };
  inputs: string[];
  systems: string[];
  decisions: string[];
  actions: string[];
  approvals: { externalAction: 'owner_required' };
  failureConditions: string[];
  verificationCriteria: string[];
  escalationPath: string;
  procedure: { id: string; version: number; rules: string[] };
  toolRouting: string[];
  intelligenceRouting: { objectiveFacts: 'deterministic'; ambiguity: 'reasoning_then_escalate' };
  supportingEvidence: string[];
  evaluationCases: string[];
  expected: { project: string; repository: string; targetRun: string; mergeSha: string; actions: number; nodes: number; nodeKeys?: string[] };
  evidenceMaxAgeSeconds: number;
  verifiedExecutionScope?: 'callable_session'; // Required for version 2.
}
