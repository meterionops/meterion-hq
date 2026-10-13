# Office incubator reader repaired — 2026-10-13

Deployed reader version 11 exposes the previously stored build briefs. Seven miniapps are derived from the existing YritystenTiedot products and shown as their own visible rows, above broader service working titles. No plan data is moved or duplicated. Tested source/projection/render path yields seven miniapps and 21 briefs. Auth index and current-owner module are unchanged.

The old persisted reader_deploy_blocked flag could not be cleared because SQL writes returned Invalid or expired requestState. The exact old UI error sentence is suppressed only when all brand briefs are present in the authenticated response; other error states are preserved. The metadata flag is historical and should be reconciled on the next successful authorized write.
