import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface LockContract {
  'status' : string,
  'durationTime' : bigint,
  'durationUnit' : bigint,
  'created' : Time,
  'provider' : string,
  'lockedTime' : [] | [Time],
  'meta' : Array<string>,
  'positionId' : bigint,
  'version' : string,
  'token0' : TokenInfo,
  'token1' : TokenInfo,
  'positionOwner' : Principal,
  'withdrawnTime' : [] | [Time],
  'unlockedTime' : [] | [Time],
  'poolName' : string,
  'contractId' : [] | [string],
  'poolId' : string,
}
export interface LockContractInit {
  'durationTime' : bigint,
  'durationUnit' : bigint,
  'provider' : string,
  'meta' : Array<string>,
  'positionId' : bigint,
  'token0' : TokenInfo,
  'token1' : TokenInfo,
  'poolName' : string,
  'poolId' : string,
}
export type Result = { 'ok' : string } |
  { 'err' : string };
export type Time = bigint;
export interface TokenInfo {
  'name' : string,
  'address' : string,
  'standard' : string,
}
export interface _anon_class_34_1 {
  'addAdmin' : ActorMethod<[string], undefined>,
  'cancelContract' : ActorMethod<[Principal], undefined>,
  'createContract' : ActorMethod<[LockContractInit], Result>,
  'cycleBalance' : ActorMethod<[], bigint>,
  'getAllAdmins' : ActorMethod<[], Array<string>>,
  'getAllContracts' : ActorMethod<[], Array<[string, LockContract]>>,
  'getContract' : ActorMethod<[string], [] | [LockContract]>,
  'getContracts' : ActorMethod<[bigint], Array<LockContract>>,
  'getOwner' : ActorMethod<[string], [] | [string]>,
  'getTotalContract' : ActorMethod<[], bigint>,
  'getUserContracts' : ActorMethod<[string, bigint], Array<LockContract>>,
  'getUserTotalTokens' : ActorMethod<[string], bigint>,
  'removeAdmin' : ActorMethod<[string], undefined>,
  'updateContractStatus' : ActorMethod<[string, string], undefined>,
  'updateInitCycles' : ActorMethod<[bigint], undefined>,
  'updateMinDeployerCycles' : ActorMethod<[bigint], undefined>,
}
export interface _SERVICE extends _anon_class_34_1 {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
