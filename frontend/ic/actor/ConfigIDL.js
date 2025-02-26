import icIDL from '@/ic/candid/ic.did';
import cyclesIDL from '@/ic/candid/cycles.did';
import ledgerIDL from '@/ic/candid/ledger.did';
import nnsIDL from '@/ic/candid/nns.did';
import icrc1IDL from '@/ic/candid/icrc1.did';
import dip20 from '@/ic/candid/dip20.did';
import ext from '@/ic/candid/ext.did';
import icrc2IDL from '@/ic/candid/icrc2.did';
import icrc3IDL from '@/ic/candid/icrc2.did';
import extNFTIDL from '@/ic/candid/extNFT.did';
import contractIDL from '@/ic/candid/contract.did';
import swapPoolIDL from '@/ic/candid/icpswap/swapPool.did';
import shortLinkIDL from '@/ic/candid/shortLink.did';
import blockIdIDL from '@/ic/candid/blockId.did';
import {idlFactory as lockDeployerIDL} from '../../../src/declarations/lock_deployer/lock_deployer.did.js';
import {idlFactory as tokenDeployerIDL} from '../../../src/declarations/token_deployer/token_deployer.did.js';
import {idlFactory as backendIDL} from '../../../src/declarations/backend/backend.did.js';
import {idlFactory as lockContractIDL} from '../../../src/declarations/lock_contract/lock_contract.did.js';
import {idlFactory as claimContractIDL} from '../../../src/declarations/claim_contract/claim_contract.did.js';
import {idlFactory as launchpadIDL} from '../../../src/declarations/launchpad/launchpad.did.js';
import {idlFactory as launchpadDetailIDL} from '../../../src/declarations/launchpad_contract/launchpad_contract.did.js';
export const preloadIdls = {
    'cycles' : cyclesIDL,
    'nns': nnsIDL,
    'ledger' : ledgerIDL,
    'icrc1' : icrc1IDL,
    'icrc2' : icrc2IDL,
    'icrc3' : icrc3IDL,
    'EXTNFT': extNFTIDL,
    'dip20': dip20,
    'ext': ext,
    'IC': icIDL,
    'contract': contractIDL,
    'shortLink': shortLinkIDL,
    'token_claim': claimContractIDL,
    'launchpad': launchpadIDL,
    'launchpad_detail': launchpadDetailIDL,
    'lock_deployer': lockDeployerIDL,
    'token_deployer': tokenDeployerIDL,
    'lock_contract': lockContractIDL,
    'backend': backendIDL,
    'swapPool': swapPoolIDL,
    'blockId': blockIdIDL,
}
export const mapIdls = {
    'aaaaa-aa' : icIDL,
    '2ouva-viaaa-aaaaq-aaamq-cai': icrc1IDL,
};
export default preloadIdls;