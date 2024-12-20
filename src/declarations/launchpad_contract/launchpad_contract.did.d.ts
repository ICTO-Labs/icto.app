import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface AffiliateStats {
  'projectedReward' : bigint,
  'volume' : bigint,
  'refCount' : bigint,
}
export interface ClaimContract {
  'title' : string,
  'vesting' : VestingInfo,
  'total' : bigint,
  'description' : string,
  'recipients' : Array<Recipient>,
}
export interface Distribution {
  'team' : ClaimContract,
  'liquidity' : FixClaimContract,
  'others' : Array<ClaimContract>,
  'fairlaunch' : FixClaimContract,
}
export interface FixClaimContract {
  'title' : string,
  'vesting' : VestingInfo,
  'total' : bigint,
  'description' : string,
}
export interface LaunchParams {
  'softCap' : bigint,
  'sellAmount' : bigint,
  'hardCap' : bigint,
  'maximumAmount' : bigint,
  'minimumAmount' : bigint,
}
export interface LaunchpadCanister {
  'checkEligibleToCommit' : ActorMethod<[], Result>,
  'commit' : ActorMethod<[bigint, [] | [string]], Result>,
  'getAffiliateStats' : ActorMethod<[string], [] | [AffiliateStats]>,
  'getParticipantInfo' : ActorMethod<[string], Participant>,
  'getRefundList' : ActorMethod<[], Array<Transaction>>,
  'getTopAffiliates' : ActorMethod<[bigint], Array<[string, AffiliateStats]>>,
  'getTransactionList' : ActorMethod<[], Array<Transaction>>,
  'install' : ActorMethod<[LaunchpadDetail, Array<string>], Result>,
  'launchpadInfo' : ActorMethod<[], LaunchpadDetail>,
  'reinstall' : ActorMethod<[], undefined>,
  'status' : ActorMethod<[], LaunchpadStatus>,
}
export interface LaunchpadDetail {
  'fee' : bigint,
  'saleToken' : TokenInfo,
  'creator' : string,
  'projectInfo' : ProjectInfo,
  'launchParams' : LaunchParams,
  'restrictedArea' : [] | [Array<string>],
  'purchaseToken' : TokenInfo,
  'affiliate' : bigint,
  'distribution' : Distribution,
  'timeline' : Timeline,
}
export interface LaunchpadStatus {
  'status' : string,
  'totalAmountCommitted' : bigint,
  'totalParticipants' : bigint,
  'installed' : boolean,
  'cycle' : bigint,
  'affiliateRewardPool' : bigint,
  'refererTransaction' : bigint,
  'whitelistEnabled' : boolean,
  'affiliate' : bigint,
  'totalAffiliateVolume' : bigint,
  'totalTransactions' : bigint,
}
export interface Participant {
  'lastDeposit' : [] | [Time],
  'totalAmount' : bigint,
  'commit' : bigint,
}
export interface ProjectInfo {
  'metadata' : [] | [Array<[string, string]>],
  'logo' : string,
  'name' : string,
  'banner' : [] | [string],
  'description' : string,
  'isAudited' : boolean,
  'links' : [] | [Array<string>],
  'isVerified' : boolean,
}
export interface Recipient {
  'note' : [] | [string],
  'address' : string,
  'amount' : bigint,
}
export type Result = { 'ok' : boolean } |
  { 'err' : string };
export type Time = bigint;
export interface Timeline {
  'startTime' : Time,
  'endTime' : Time,
  'createdTime' : Time,
  'claimTime' : Time,
  'listingTime' : Time,
}
export interface TokenInfo {
  'decimals' : bigint,
  'metadata' : [] | [Uint8Array | number[]],
  'logo' : string,
  'name' : string,
  'transferFee' : bigint,
  'symbol' : string,
  'canisterId' : string,
}
export interface Transaction {
  'method' : string,
  'time' : Time,
  'txId' : [] | [bigint],
  'participant' : string,
  'amount' : bigint,
}
export interface VestingInfo {
  'duration' : bigint,
  'unlockFrequency' : bigint,
  'cliff' : bigint,
}
export interface _SERVICE extends LaunchpadCanister {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
