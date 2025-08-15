// Service for interacting with the Distribution Canister on the Internet Computer

// import type { DistributionCampaign, DistributionRecord, Participant } from '@/types/distribution';

// // Mock data for demonstration purposes
// const mockCampaigns: DistributionCampaign[] = [
//   {
//     id: '1',
//     title: 'Q1 2024 Community Airdrop',
//     type: 'Airdrop',
//     token: { symbol: 'ICP', name: 'Internet Computer' },
//     totalAmount: 1000000,
//     distributedAmount: 450000,
//     startTime: new Date('2024-01-01T00:00:00Z'),
//     endTime: new Date('2024-03-31T23:59:59Z'),
//     method: 'Immediate',
//     isWhitelisted: true,
//     status: 'Ongoing',
//     creator: 'a3g4s-5d6f7-g8h9j-0k1l2-m3n4o-p5q6r-s7t8u-v9w0x-y1z2a-3b4c5-d6e7f',
//     description: 'Airdrop for early community members and contributors.',
//   },
//   {
//     id: '2',
//     title: 'Seed Investor Vesting',
//     type: 'Vesting',
//     token: { symbol: 'GHOST', name: 'Ghost Token' },
//     totalAmount: 5000000,
//     distributedAmount: 1250000,
//     startTime: new Date('2023-12-01T00:00:00Z'),
//     endTime: new Date('2025-12-01T00:00:00Z'),
//     method: 'Linear',
//     isWhitelisted: true,
//     status: 'Ongoing',
//     creator: 'b4h5j-6k7l8-m9n0o-p1q2r-s3t4u-v5w6x-y7z8a-9b0c1-d2e3f-4g5h6-i7j8k',
//     description: 'Vesting schedule for seed round investors with a 24-month linear unlock.',
//   },
//   {
//     id: '3',
//     title: 'Team Token Lockup',
//     type: 'Lock',
//     token: { symbol: 'WRLD', name: 'World Token' },
//     totalAmount: 10000000,
//     distributedAmount: 0,
//     startTime: new Date('2024-06-01T00:00:00Z'),
//     endTime: new Date('2026-06-01T00:00:00Z'),
//     method: 'Cliff',
//     isWhitelisted: true,
//     status: 'Upcoming',
//     creator: 'c5i6k-7l8m9-n0o1p-q2r3s-t4u5v-w6x7y-z8a9b-0c1d2-e3f4g-5h6i7-j8k9l',
//     description: 'Team tokens locked for 24 months with a 6-month cliff.',
//   },
//   {
//     id: '4',
//     title: 'Public Sale Round 1',
//     type: 'Airdrop',
//     token: { symbol: 'ICP', name: 'Internet Computer' },
//     totalAmount: 250000,
//     distributedAmount: 250000,
//     startTime: new Date('2023-11-10T00:00:00Z'),
//     endTime: new Date('2023-11-11T00:00:00Z'),
//     method: 'Immediate',
//     isWhitelisted: false,
//     status: 'Ended',
//     creator: 'd6j7l-8m9n0-o1p2q-r3s4t-u5v6w-x7y8z-a9b0c-1d2e3-f4g5h-6i7j8-k9l0m',
//     description: 'First round of the public token sale.',
//   },
// ];

// Service for real-time distribution data integration

import { Actor } from '@dfinity/agent';
import { useAuthStore, distributionContractActor, backendActor } from '@/stores/auth';
import type { DistributionCanister, DistributionStats, DistributionDetails, Result } from '@/types/distribution';
import { Principal } from '@dfinity/principal';
import { IcrcService } from './icrc';
import type { Token } from '@/types/token';
import { toast } from 'vue-sonner';

export class DistributionService {
  // Get user's related distribution canisters from backend (distributions where user is recipient)
  static async getUserDistributions(): Promise<DistributionCanister[]> {
    const authStore = useAuthStore();
    const backend = backendActor({ anon: false, requiresSigning: true });
    
    if (!backend) {
      throw new Error('Backend actor not available');
    }
    
    try {
      // Use Factory Registry API to get distributions where user is a recipient
      const result = await backend.getRelatedCanistersByType({ DistributionRecipient: null }, []); // Current user
      
      if ('Ok' in result) {
        return result.Ok.map((canisterId: any) => ({
          canisterId: canisterId.toString(),
          relationshipType: 'DistributionRecipient' as const,
          metadata: { 
            name: 'Distribution Campaign', // Default name, will be updated when we fetch individual canister data
            isActive: true 
          }
        }));
      }
      
      if ('Err' in result) {
        console.warn('No joined distributions found or error:', result.Err);
        return []; // Return empty array instead of throwing error
      }
      
      throw new Error('Unexpected response format');
    } catch (error) {
      console.error('Error fetching user distributions:', error);
      // Return empty array instead of throwing to prevent app crash
      return [];
    }
  }

  // Get real-time stats from individual distribution canister
  static async getDistributionStats(canisterId: string): Promise<DistributionStats> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      
      const stats = await distributionContract.getStats();
      return stats as unknown as DistributionStats;
    } catch (error) {
      console.error(`Error fetching stats for ${canisterId}:`, error);
      throw error;
    }
  }

  //Get canister info
  static async getCanisterInfo(canisterId: string): Promise<any> {
    const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
    const info = await distributionContract.getCanisterInfo();
    return info;
  }

  // Get complete distribution details
  static async getDistributionDetails(canisterId: string): Promise<DistributionDetails> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      
      const details = await distributionContract.getConfig();
      return details as unknown as DistributionDetails;
      
    } catch (error) {
      console.error(`Error fetching details for ${canisterId}:`, error);
      throw error;
    }
  }

  // Claim tokens from distribution
  static async claimTokens(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.claim();
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error claiming tokens for ${canisterId}:`, error);
      throw error;
    }
  }

  //Register for a distribution
  static async register(canisterId: string): Promise<Result> {
    const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
    const result = await distributionContract.register();
    return result as unknown as Result;
  }

  // ================ ADMIN MANAGEMENT FUNCTIONS ================
  
  // Initialize the distribution contract
  static async initializeContract(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.init();
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error initializing contract ${canisterId}:`, error);
      throw error;
    }
  }

  // Activate distribution
  static async activateDistribution(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.activate();
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error activating distribution ${canisterId}:`, error);
      throw error;
    }
  }

  // Pause distribution
  static async pauseDistribution(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.pause();
      if ('ok' in result) {
        toast.success('Distribution paused')
      } else {
        toast.error('Error: ' + result.err)
      }
      return result as unknown as Result;

    } catch (error) {
      console.error(`Error pausing distribution ${canisterId}:`, error);
      throw error;
    }
  }

  // Resume distribution
  static async resumeDistribution(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.resume();
      if ('ok' in result) {
        toast.success('Distribution resumed')
      } else {
        toast.error('Error: ' + result.err)
      }
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error resuming distribution ${canisterId}:`, error);
      throw error;
    }
  }

  // Cancel distribution
  static async cancelDistribution(canisterId: string): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.cancel();
      if ('ok' in result) {
        toast.success('Distribution cancelled')
      } else {
        toast.error('Error: ' + result.err)
      }
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error cancelling distribution ${canisterId}:`, error);
      throw error;
    }
  }

  // ================ PARTICIPANT MANAGEMENT ================

  // Get all participants
  static async getAllParticipants(canisterId: string): Promise<any[]> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const participants = await distributionContract.getAllParticipants();
      return participants as any[];
    } catch (error) {
      console.error(`Error fetching participants for ${canisterId}:`, error);
      throw error;
    }
  }

  // Get specific participant
  static async getParticipant(canisterId: string, principalId: string): Promise<any> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const participant = await distributionContract.getParticipant(Principal.fromText(principalId));
      return participant;
    } catch (error) {
      console.error(`Error fetching participant ${principalId} for ${canisterId}:`, error);
      throw error;
    }
  }

  // Add participants (admin only)
  static async addParticipants(canisterId: string, participants: Array<[string, bigint]>): Promise<Result> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const result = await distributionContract.addParticipants(participants as unknown as [Principal, bigint][]);
      return result as unknown as Result;
    } catch (error) {
      console.error(`Error adding participants to ${canisterId}:`, error);
      throw error;
    }
  }

  // Get claim history
  static async getClaimHistory(canisterId: string, principalId?: string): Promise<any[]> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const history = await distributionContract.getClaimHistory(principalId ? [Principal.fromText(principalId)] : []);
      return history as any[];
    } catch (error) {
      console.error(`Error fetching claim history for ${canisterId}:`, error);
      throw error;
    }
  }

  // Get claimable amount for specific participant
  static async getClaimableAmount(canisterId: string, principalId: string): Promise<bigint> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const amount = await distributionContract.getClaimableAmount(Principal.fromText(principalId));
      return amount as bigint;
    } catch (error) {
      console.error(`Error fetching claimable amount for ${principalId} in ${canisterId}:`, error);
      throw error;
    }
  }

  // ================ CONTRACT MONITORING ================

  // Get contract balance (query version - faster)
  static async getContractBalance(token: Token, canisterId: string): Promise<bigint> {
    try {
      if (!token) {
        throw new Error('Token not found');
      }
      const balance = await IcrcService.getIcrc1Balance(token, Principal.fromText(canisterId));
      console.log('balance', balance)
      return balance as bigint;
    } catch (error) {
      console.error(`Error fetching contract balance for ${token.canisterId.toString()}:`, error);
      throw error;
    }
  }

  // Get contract balance (async version - more accurate)
  static async getContractBalanceAsync(canisterId: string): Promise<bigint> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const balance = await distributionContract.getContractBalanceAsync();
      return balance as bigint;
    } catch (error) {
      console.error(`Error fetching async contract balance for ${canisterId}:`, error);
      throw error;
    }
  }

  // Get distribution status
  static async getDistributionStatus(canisterId: string): Promise<string> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const status = await distributionContract.getStatus();
      return Object.keys(status)[0]; // Extract variant key
    } catch (error) {
      console.error(`Error fetching status for ${canisterId}:`, error);
      throw error;
    }
  }

  // Health check
  static async healthCheck(canisterId: string): Promise<boolean> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const health = await distributionContract.healthCheck();
      return health as boolean;
    } catch (error) {
      console.error(`Error checking health for ${canisterId}:`, error);
      throw error;
    }
  }

  // ================ TIMER MANAGEMENT ================

  // Start timer
  static async startTimer(canisterId: string): Promise<void> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      await distributionContract.startTimer();
    } catch (error) {
      console.error(`Error starting timer for ${canisterId}:`, error);
      throw error;
    }
  }

  // Cancel timer
  static async cancelTimer(canisterId: string): Promise<void> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      await distributionContract.cancelTimer();
    } catch (error) {
      console.error(`Error cancelling timer for ${canisterId}:`, error);
      throw error;
    }
  }

  // Get timer status
  static async getTimerStatus(canisterId: string): Promise<{ timerId: bigint; isRunning: boolean }> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const status = await distributionContract.getTimerStatus();
      return status as { timerId: bigint; isRunning: boolean };
    } catch (error) {
      console.error(`Error fetching timer status for ${canisterId}:`, error);
      throw error;
    }
  }

  // ================ ELIGIBILITY FUNCTIONS ================

  // Check eligibility (synchronous - for simple cases)
  static async checkEligibilitySync(canisterId: string, principalId: string): Promise<boolean> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      const eligible = await distributionContract.checkEligibilitySync(Principal.fromText(principalId));
      return eligible as boolean;
    } catch (error) {
      console.error(`Error checking eligibility for ${principalId} in ${canisterId}:`, error);
      throw error;
    }
  }

  // ================ CONVENIENCE FUNCTIONS ================

  // Get comprehensive distribution data for admin view
  // ================ USER CONTEXT FUNCTIONS ================

  // Get comprehensive user context (whoami function)
  static async getUserContext(canisterId: string): Promise<{
    principal: string;
    isOwner: boolean;
    isRegistered: boolean;
    isEligible: boolean;
    participant: any;
    claimableAmount: bigint;
    distributionStatus: string;
    canRegister: boolean;
    canClaim: boolean;
    registrationError?: string;
  }> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      const context = await distributionContract.whoami();
      
      return {
        principal: context.principal.toString(),
        isOwner: context.isOwner,
        isRegistered: context.isRegistered,
        isEligible: context.isEligible,
        participant: context.participant,
        claimableAmount: context.claimableAmount as bigint,
        distributionStatus: Object.keys(context.distributionStatus)[0], // Extract variant key
        canRegister: context.canRegister,
        canClaim: context.canClaim,
        registrationError: context.registrationError?.[0] // Extract optional text
      };
    } catch (error) {
      console.error(`Error fetching user context for ${canisterId}:`, error);
      throw error;
    }
  }

  static async getDistributionAdminData(canisterId: string): Promise<{
    config: any;
    stats: DistributionStats;
    participants: any[];
    claimHistory: any[];
    canisterInfo: any;
    timerStatus: { timerId: bigint; isRunning: boolean };
    contractBalance: bigint;
  }> {
    try {
      const [config, stats, participants, claimHistory, canisterInfo, timerStatus, contractBalance] = await Promise.all([
        this.getDistributionDetails(canisterId),
        this.getDistributionStats(canisterId),
        this.getAllParticipants(canisterId),
        this.getClaimHistory(canisterId),
        this.getCanisterInfo(canisterId),
        this.getTimerStatus(canisterId),
        this.getContractBalance(canisterId)
      ]);

      return {
        config,
        stats,
        participants,
        claimHistory,
        canisterInfo,
        timerStatus,
        contractBalance
      };
    } catch (error) {
      console.error(`Error fetching comprehensive admin data for ${canisterId}:`, error);
      throw error;
    }
  }
};
