# Source Lifecycle v1

## States

discovered  
analyzed  
candidate  
active  
degraded  
disabled  

## Invariant

A source must always be in exactly one lifecycle state.

## Allowed transitions

discovered → analyzed  
analyzed → candidate  
candidate → active  
active → degraded  
degraded → active  
any → disabled
