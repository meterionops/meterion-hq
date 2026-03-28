import React from "react";
import { OperatorGuidance } from "./decisionSurfaceTypes";

type Props = {
  guidance: OperatorGuidance | null;
};

const badgeColor = (confidence?: string) => {
  switch (confidence) {
    case "high":
      return "bg-green-100 text-green-700";
    case "medium":
      return "bg-yellow-100 text-yellow-700";
    case "low":
      return "bg-gray-100 text-gray-600";
    default:
      return "bg-gray-100 text-gray-500";
  }
};

export const OperatorGuidanceCard: React.FC<Props> = ({ guidance }) => {
  if (!guidance || guidance.status === "none") {
    return null;
  }

  return (
    <div className="border rounded-xl p-4 bg-white space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-700">
          Operator Guidance
        </h3>

        {guidance.confidence && (
          <span
            className={`text-xs px-2 py-1 rounded ${badgeColor(
              guidance.confidence
            )}`}
          >
            {guidance.confidence}
          </span>
        )}
      </div>

      {/* Summary */}
      {guidance.summary && (
        <div className="text-sm text-gray-800">{guidance.summary}</div>
      )}

      {/* Suggested check */}
      {guidance.suggestedCheck && (
        <div>
          <div className="text-xs text-gray-500 mb-1">
            Suggested check
          </div>
          <div className="text-sm text-gray-900">
            {guidance.suggestedCheck}
          </div>
        </div>
      )}

      {/* Rationale */}
      {guidance.rationale && (
        <div>
          <div className="text-xs text-gray-500 mb-1">
            Why this
          </div>
          <div className="text-sm text-gray-700">
            {guidance.rationale}
          </div>
        </div>
      )}

      {/* Do not change yet */}
      {guidance.doNotChangeYet &&
        guidance.doNotChangeYet.length > 0 && (
          <div>
            <div className="text-xs text-gray-500 mb-1">
              Do not change yet
            </div>
            <ul className="text-sm text-gray-600 list-disc ml-5">
              {guidance.doNotChangeYet.map((item, i) => (
                <li key={i}>{item}</li>
              ))}
            </ul>
          </div>
        )}
    </div>
  );
};
