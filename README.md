# IntentLock MultiSig

A multisig controller for intent-based transaction execution on the Stacks blockchain. IntentLock MultiSig enables authorized signers to create and approve intents with a configurable threshold, ensuring multiple signers must authorize transactions before execution.

## Overview

IntentLock MultiSig is a Clarity smart contract that implements multisig approval logic for intent execution. Multiple authorized signers can collaborate to approve intents, with execution gated by a configurable approval threshold. This provides decentralized control over high-value operations with transparent on-chain verification.

## Features

✓ **Multisig Authorization** - Register authorized signers during initialization  
✓ **Intent Creation** - Approved signers create intents for collective approval  
✓ **Threshold-Based Execution** - Configurable approval requirement (e.g., 2-of-3, 3-of-5)  
✓ **Duplicate Prevention** - Prevent same signer from approving intent twice  
✓ **Execution Gating** - Intents execute only when threshold met  
✓ **Replay Protection** - Executed intents locked to prevent re-execution  
✓ **Immutable Records** - All intents and approvals tracked on-chain  

## Contract Functions

### Initialization

- `initialize(initial-signers, required)` - Initialize multisig with signers and threshold
  - `initial-signers`: List of authorized signer principals (max 10)
  - `required`: Approval threshold (number of approvals needed for execution)
  - Can only be called once at deployment
  - Returns: Success confirmation

### Signer Functions

- `create-intent()` - Create a new intent for approval
  - Only callable by authorized signers
  - Auto-increments intent ID
  - Initializes intent with 0 approvals and executed=false
  - Returns: Unique intent ID

- `approve-intent(id)` - Approve an existing intent
  - `id`: Intent ID to approve
  - Only callable by authorized signers
  - Prevents duplicate approvals from same signer
  - Increments approval counter for intent
  - Returns: Success confirmation or error code

### Public Functions

- `execute-intent(id)` - Execute intent if threshold met
  - `id`: Intent ID to execute
  - Validates approval count >= threshold (ERR-THRESHOLD-NOT-MET)
  - Marks intent as executed to prevent replay
  - Can be called by any principal (execution delegated to vault)
  - Returns: Success confirmation or error code

### Read-Only Functions

- `intent-status(id)` - Query intent approval and execution status
  - Returns: Intent data with approvals count and executed flag

- `is-signer(signer)` - Check if principal is authorized signer
  - Returns: Boolean indicating signer status

## State Management

### Configuration Variables

- **threshold**: Approval threshold required for execution (set during initialization)
- **intent-counter**: Auto-incrementing counter for unique intent IDs

### Storage Maps

- **signers**: Stores authorized signer principals
  - `signer`: Principal address
  - `active`: Boolean indicating active status

- **intents**: Stores intent data keyed by ID
  - `id`: Unique intent identifier
  - `approvals`: Number of approvals received
  - `executed`: Boolean indicating execution status

- **approvals**: Nested map for duplicate prevention
  - `id`: Intent ID
  - `signer`: Signer principal
  - `approved`: Boolean flag


## Intent Lifecycle
