# ERC-20 Token Implementation

Learning project built to understand token standards and the compliance 
gap between ERC-20 and ERC-3643 (T-REX).

## What this covers
- ERC-20 token contract implementation in Solidity
- Built and tested using Foundry (Forge, Cast, Anvil)
- Studied how ERC-20 lacks compliance controls that ERC-3643 enforces
  on-chain (identity verification, transfer restrictions, KYC compliance)

## Tech Stack
- Solidity
- Foundry

## Key Learning
ERC-20 allows unrestricted transfers between any wallets. ERC-3643 (T-REX)
adds an identity and compliance layer — transfers only succeed between
KYC-verified wallets that pass compliance rules. This is critical for
real-world asset tokenization.
