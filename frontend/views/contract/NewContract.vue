<script setup>
	import {ref, computed} from "vue";
	import {validateAddress, validatePrincipal, showError} from "@/utils/common"
	import {currencyFormat} from "@/utils/token"
	import { useWalletStore } from '@/store/wallet'
    import LoadingLabel from "@/components/LoadingLabel.vue"
	import EventBus from "@/services/EventBus";
	import { useAssetStore } from "@/store/token";
	import { useGetMyBalance } from '@/services/Token';
	import PreviewChart from '@/components/contract/PreviewChart.vue';
	import VestingChart from '@/components/contract/VestingChart.vue';
    import { DURATION, SCHEDULE} from "@/config/constants"
    import Codemirror from "codemirror-editor-vue3";


	import VueMultiselect from 'vue-multiselect'
	import config from '@/config'
	const isLoading = ref(false);
	const storeAsset = useAssetStore();
	const walletStore = useWalletStore();
	const token = ref({symbol: 'ICP', name: 'Internet Computer', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', standard: 'icrc1', decimals: 8, fee: 10000});
	const tokenBalance = ref(walletStore.wallet.balance);
	const totalAmount = ref(0);
	const newRecipient = ref({amount:"", address: "", title: "", note: ""});
	const recipients = ref([]);
	const whitelistDistribution = ref(true);
	const props = defineProps({
		options: {
			type: Array,
			required: true
		}
		});

	const contractDataComputed = computed(() => ({
	...contractData.value
	}))
	const contractData = ref({
		name: "Test",
		description: "Test",
		editorMode: false,
		unlockImmediately: false,
		startNow: true,
		startDate: new Date(),
		startTime: new Date(),
		durationUnit: 30,
		durationTime: 86400,
		unlockSchedule: 86400,
		cliffUnit: 0,
		cliffTime: 2628002,
		totalAmount: 0,
		recipients: [],
		maxRecipients: 0,
		blockId: 0,
		allowCancel: false,
		autoTransfer: false,
		initialUnlock: 0,
		distributionType: whitelistDistribution.value
	});
	const unlockFrequency = ref(86400);
	const tokenPerRecipient = ref(0);
	const totalRecipient = ref(0);
    const codemirror = ref(null);
	const recipientsEdit = ref("");
	const cmOptions = ref({
        mode: "text/javascript", // Language mode
        theme: "dracula", // Theme
    });
	const customLabel = ({ name, canisterId })=>{
		return `${name} | Canister ID: ${canisterId}`
    }
	const toggleUnlock = ()=>{
		contractData.value.unlockImmediately = !contractData.value.unlockImmediately;
		if(contractData.value.unlockImmediately){
			contractData.value.durationUnit = 0;
			contractData.value.cliffUnit = 0;
		}else{
			contractData.value.durationUnit = 1;
		}
	}
	const calculateTokenPerRecipient = ()=>{
		tokenPerRecipient.value = contractData.value.totalAmount/totalRecipient.value;
	}
	const switchMode = ()=>{
		contractData.value.editorMode = !contractData.value.editorMode;
		switchData(!contractData.value.editorMode);
	}
	const loadSampleData = ()=>{
        recipientsEdit.value = `vkdhi-vlxfv-56jyt-tcyxp-qlhlk-4lnpb-k2r4q-uctef-ppvdr-iphm5-zqe,10,developer
sarfp-y2id5-s2kqj-dgkrz-tk7ft-fpvhy-drpzc-bq7t3-sbqp7-txxlv-iqe,20,marketing
7mrjg-jibqe-nd4lb-xxksz-lv4vu-emumn-jgml4-gqlcy-cqq3z-rypfs-jae,10
5s246-2xf3s-vym4q-rxwf5-k6snu-anhsz-2tze5-vaxuh-alkvb-dudii-bqe,15,designer
zxcjx-7yvay-ow7hh-nbocq-5aaru-n7nwq-xyhau-jnr6m-f36ho-xzufk-rae,50`;
		calTotalToken();
    }
	const setSelectedToken = async ()=>{
		resetRecipients();
		tokenBalance.value = 0;
		await getTokenBalance();
	}
	const checkingRecipients = ()=>{
		let _recipients = recipientsEdit.value.split('\n');
        let _totalAmount = 0;
        let _totalError = 0;
        let _totalRecipients = 0;
        _recipients.forEach((item, idx)=>{
            let _item = item.split(',');
            if(_item.length >= 2){
                //Check recipient principal
                if(validatePrincipal(_item[0])){
					//Check amount is number
					if(isNaN(_item[1].trim())){
						codemirror.value.cminstance.addLineClass(idx, "background", "codemirror-error-line");
					}else{
						_totalAmount += parseInt(_item[1].trim())||0;
						_totalRecipients++;
						codemirror.value.cminstance.removeLineClass(idx, "background", "codemirror-error-line");
					}
                }else{
                    codemirror.value.cminstance.addLineClass(idx, "background", "codemirror-error-line");
                    _totalError++;
                }
            }
        });
		calTotalToken();
	}

	//Switch data from GUI to Edit mode
	const switchData = (fromEditMode=true)=>{
		if(fromEditMode){
			recipients.value = JSON.stringify(recipientsEdit.value);
			let _recipients = recipientsEdit.value.split('\n');
			let _recipientsTmp = [];
			_recipients.forEach((item, idx)=>{
				let _item = item.split(',');
				if(_item.length >= 2){
					//Switch only validate principal
					if(validatePrincipal(_item[0])){
						_recipientsTmp.push({address: _item[0], amount: parseInt(_item[1])|0, note: _item[2]??""});
					}
				}
			});
			recipients.value = _recipientsTmp;
		}else{
			recipientsEdit.value = recipients.value.map(recipient => `${recipient.address},${recipient.amount},${recipient.note}`).join('\n');
		}
		//Recall total amount
		calTotalToken();
	};

	const changeFrequency = (e)=>{
		if(e.target.value == -2){ //Linear
			contractData.value.unlockSchedule = 0;//Number(contractData.value.durationUnit)*Number(contractData.value.durationTime);
		}else if(e.target.value == -1){ //Single
			contractData.value.durationUnit = 1;
			contractData.value.cliffUnit = 0;
			contractData.value.unlockSchedule = 0;
		}else if(e.target.value == 0){ //Immediately
			contractData.value.durationUnit = 0;
			contractData.value.cliffUnit = 0;
			contractData.value.unlockSchedule = 0;
		}else{ //Others schedule
			contractData.value.unlockSchedule = Number(e.target.value);
		}
		validateVesting();
	}
	const validateVesting = () => {
    // Đảm bảo các giá trị không âm
    contractData.value.cliffUnit = Math.max(0, contractData.value.cliffUnit);
    contractData.value.durationUnit = Math.max(0, contractData.value.durationUnit);

    if (unlockFrequency.value == -1) {
        // Single unlock - Sử dụng duration làm thời điểm unlock
        contractData.value.unlockSchedule = Number(contractData.value.durationUnit) * Number(contractData.value.durationTime);
		contractData.value.cliffUnit = 0;
    } else if (unlockFrequency.value == 0) {
        // Unlock immediately
        contractData.value.durationUnit = 0;
        contractData.value.cliffUnit = 0;
        contractData.value.unlockSchedule = 0;
    } else {
        // Standard vesting
        contractData.value.unlockSchedule = unlockFrequency.value;
    }

    // Kiểm tra cliff không được lớn hơn duration
    let cliffInSeconds = contractData.value.cliffUnit * contractData.value.durationTime;
    let durationInSeconds = contractData.value.durationUnit * contractData.value.durationTime;
    
    if (cliffInSeconds > durationInSeconds) {
        contractData.value.cliffUnit = contractData.value.durationUnit;
    }

    // Đảm bảo unlock schedule không lớn hơn tổng thời gian
    if (contractData.value.unlockSchedule > 0) {
        let totalDuration = Number(contractData.value.durationTime) * Number(contractData.value.durationUnit);
        if (totalDuration < Number(contractData.value.unlockSchedule)) {
            contractData.value.unlockSchedule = contractData.value.durationTime;
        }
    }

	//Check unlock frequency not greater than duration
	if(unlockFrequency.value > 0 && unlockFrequency.value > Number(contractData.value.durationTime)*Number(contractData.value.durationUnit)){
		unlockFrequency.value = contractData.value.durationTime;
		showError("Unlock frequency cannot be greater than duration!");
	}
}
	const validateVesting1 = ()=>{
		if(unlockFrequency.value == -1){
			contractData.value.unlockSchedule = Number(contractData.value.durationUnit)*Number(contractData.value.durationTime);
		}else if(unlockFrequency.value == 0){
			contractData.value.durationUnit = 0;
			contractData.value.cliffUnit = 0;
		}else{
			contractData.value.unlockSchedule = unlockFrequency.value;
		}

		if(contractData.value.cliffUnit < 0) contractData.value.cliffUnit = 0;
		if(contractData.value.durationUnit < 0) contractData.value.durationUnit = 0;
		let cliffInSeconds = contractData.value.cliffUnit*contractData.value.cliffTime;
		let durationInSeconds = contractData.value.durationUnit*contractData.value.durationTime;
		let unlockSchedule = contractData.value.unlockSchedule;
		if (cliffInSeconds > durationInSeconds) {
			contractData.value.cliffUnit = contractData.value.durationUnit;
			contractData.value.cliffTime = contractData.value.durationTime;
		}
		if (contractData.value.unlockSchedule > 0 && Number(contractData.value.durationTime)*Number(contractData.value.durationUnit) < Number(contractData.value.unlockSchedule)){
			contractData.value.unlockSchedule = contractData.value.durationTime;
		}
	}
	const calTotalToken = ()=>{
		console.log('calTotalToken');
		if(!whitelistDistribution.value) return;//Skip calculate if public distribution
		if(contractData.value.editorMode){
			contractData.value.totalAmount = recipientsEdit.value.split('\n').reduce((acc,cur) => {
				let _cur = cur.split(',');
				if(_cur.length >= 2 && validatePrincipal(_cur[0])){
					if(!isNaN(_cur[1].trim())){
						return acc + parseInt(_cur[1]);
					}
				}
				return acc;
			}, 0);
		}else{
			contractData.value.totalAmount = recipients.value.reduce((acc,cur) => acc + parseInt(cur.amount), 0);
		}
	}
	const getTokenBalance = async ()=>{
		isLoading.value = true;
		contractData.value.totalAmount = 0;
		tokenBalance.value = await useGetMyBalance(token.value.canisterId);
		isLoading.value = false;
		calTotalToken();
	}
	const resetInput = ()=>{
		newRecipient.value = {amount:0, address: "", note: ""};
	}
	const resetRecipients = ()=>{ recipients.value = []};
	const removeRecipient = (idx)=>{
		recipients.value.splice(idx, 1);
		calTotalToken();
	}
	const findRecipientIdx = (address)=>{
		return recipients.value.findIndex(x => x.address == address);
	}
	const addRecipient = ()=>{
		let _to = newRecipient.value.address.trim();
		if(token.value.standard  != 'ledger' && !validatePrincipal(_to)){
			showError("Please use a valid Principal ID!");
			return;
		}
		if(newRecipient.value.amount <= 0){
			showError("Please enter a valid amount!");
			return;
		}
		let idx = findRecipientIdx(_to);
		if(idx > -1){//Update amount if existed
			recipients.value[idx].amount += Number(newRecipient.value.amount);
			recipients.value[idx].note = newRecipient.value.note??"";
		}else{
			recipients.value.push({address:_to, amount: Number(newRecipient.value.amount), title: newRecipient.value.title??"", note:newRecipient.value.note??""})
		}

		resetInput();
		calTotalToken();
	}
	const importToken = ()=>{
		EventBus.emit("showImportTokenModal", true)
	}
	const deployToken = ()=>{
		EventBus.emit("showDeployTokenModal", true)
	}
	
	const tokenInfo = computed(()=>{
		return token.value;
	})

	const reviewContract = ()=>{
		switchData(true);//Trigger switch data from edit mode to GUI mode
		if(whitelistDistribution.value && recipients.value.length == 0){
			showError("No recipient!")
			return;
		}
		//total recipients and total token spent is require for public distribution
		if(!whitelistDistribution.value){
			if(contractData.value.totalAmount == 0){
				showError("Total amount is required!")
				return;
			}
			if(totalRecipient.value == 0){
				showError("Total recipients is required!")
				return;
			}
		}

		contractData.value.recipients = whitelistDistribution.value ? recipients.value : [];
		contractData.value.token = token.value;
		contractData.value.maxRecipients = totalRecipient.value;
		contractData.value.totalAmount = contractData.value.totalAmount;
		contractData.value.distributionType = whitelistDistribution.value ? {Whitelist: null} : {Public: null};
		contractData.value.cliffTime = Number(contractData.value.durationTime);
		contractData.value.initialUnlock = whitelistDistribution.value ? Number(contractData.value.initialUnlock) : 0;
		contractData.value.vestingType = unlockFrequency.value == -1 ? { Single: null } : { Standard: null };
		console.log('preview', contractData.value.totalAmount, contractData.value);

		EventBus.emit("showContractDetailsModal", {...contractData.value, status: true})
	}
</script>
<template>
    <Toolbar :current="`New Contract`" :parents="[{title: 'Token Claim', to: '/token-claim'}]"/>

	<form class="form" @submit.prevent="reviewContract">
		<div class="row gy-5 g-xl-8">
			<div class="col-md-7 fv-row">
				<div class="card card-xl-stretch mb-xl-8">
					<div class="card-header align-items-center">
						<label class="fs-4 fw-bold form-label mb-2 text-primary">Create New Contract</label>
					</div>
					<div class="card-body pt-5 pb-2">
						<div class="w-100">
							<div class="row mb-5">
								<div class="col-md-12 fv-row">
									<label class="d-flex align-items-center fs-6 fw-bold mb-2"><span class="required">Contract Name</span></label>
									<input type="text" class="form-control fw-normal" v-model="contractData.name" name="name" placeholder="Your contract name, campaign..." required />
								</div>
							</div>
							<div class="row mb-5">
								<div class="col-md-12 fv-row">
									<label class="d-flex align-items-center fs-6 fw-bold mb-2"><span class="required">Description</span></label>
									<textarea class="form-control fw-normal" v-model="contractData.description" name="description" placeholder="Contract description" required></textarea>
								</div>
							</div>
							<div class="row mb-5">
								<div class="col-md-8 fv-row">
									<label class="d-flex align-items-center fs-6 fw-bold mb-2">
										<span class="required">Token</span> 
										<i class="fas fa-exclamation-circle ms-2 fs-7" data-bs-toggle="tooltip" title="Specify your Token"></i>
										<a href="#" class="badge badge-light-primary ms-5" @click="importToken">+ Import</a>
										<a href="#" class="badge badge-light-danger ms-5" @click="deployToken">+ Deploy New Token</a>
									</label>

									<VueMultiselect v-model="token" :options="storeAsset.assets" track-by="name" @update:model-value="setSelectedToken" :option-height="40" :custom-label="customLabel" :allow-empty="false" placeholder="Select Token..." selectLabel="" deselectLabel="">
										<template v-slot:singleLabel="{ option }">
											<img class="option__image" :src="`https://${config.CANISTER_STORAGE_ID}.raw.icp0.io/${option.canisterId}.png`">
											<span class="option__desc">
												<span class="option__title">{{ option.name }} ({{ option.symbol }} )
													<span class="badge badge-light-primary ms-auto">{{ option.standard?option.standard.toUpperCase():'' }}</span>
												</span>
											</span>
										</template>
										<template v-slot:option="{ option }">
											<img class="option__image" :src="`https://${config.CANISTER_STORAGE_ID}.raw.icp0.io/${option.canisterId}.png`" alt="Select Token">
											<span class="option__desc">
												<span class="option__title">{{ option.name }} ({{ option.symbol }} ) · {{ option.canisterId }} 
													<div class="badge badge-light-primary ms-auto">{{ option.standard?option.standard.toUpperCase():'' }}</div></span>
											</span>
										</template>
									</VueMultiselect>

								</div>
								<div class="col-md-4 fv-row">
									<label class="fs-6 fw-bold form-label mb-2">Balance
										<LoadingLabel 
											:loading="isLoading"
											class="badge badge-light-primary ms-5"
											@click="getTokenBalance"><i class="fas fa-arrows-rotate"></i> Refresh
										</LoadingLabel>

									</label>
									<input type="text" readonly class="form-control form-control-solid" :value="currencyFormat(tokenBalance)">
								</div>
							</div>
							<div class="row mb-3">
								<div class="col-md-6 fv-row">
									<label class="required fs-6 fw-bold form-label mb-2">Distribution Type</label>
									<div class="row fv-row">
										<div class="col-12">
											<select name="releaseFrequencyPeriod" class="form-select" v-model="whitelistDistribution">
													<option :value="false">Public/Airdrops</option>
													<option :value="true" selected>Whitelist</option>
											</select>
										</div>
									</div>
								</div>
								<div class="col-md-6 fv-row">
									<label class="required fs-6 fw-bold form-label mb-2">Initial Unlock (%)</label>
									<div class="row fv-row">
										<div class="col-12">
											<input type="text" class="form-control" v-model="contractData.initialUnlock" required placeholder="Enter initial unlock percent" min="0" max="100" @change="validateVesting" :disabled="!whitelistDistribution" />
										</div>
									</div>
								</div>
							</div>
							<div class="row mb-3">
								<div class="col-md-4 fv-row">
									<label class="required fs-6 fw-bold form-label mb-2">Unlock frequency</label>
									<div class="row fv-row">
										<div class="col-12">
											<select name="releaseFrequencyPeriod" class="form-select" @change="changeFrequency" v-model="unlockFrequency">
												<optgroup label="Unlock Immediately">
													<option value="0">Unlock Immediately</option>
												</optgroup>
												<optgroup label="Single">
													<option value="-1">Fully unlocks after...</option>
												</optgroup>
												<!-- <optgroup label="Unlock linear">
													<option value="60">Unlock Linear</option>
												</optgroup> -->
												<optgroup label="Or choose schedule">
													<!-- <option value="60">Per Minute</option>
													<option value="3600">Hourly</option> -->
													<option value="86400">Daily</option>
													<option value="604800">Weekly</option>
													<option value="2628002">Monthly</option>
													<option value="7884006">Quarterly</option>
													<option value="31536000">Yearly</option>
												</optgroup>
											</select>
										</div>
									</div>
								</div>
								<div class="col-md-4 fv-row">
									<label class="required fs-6 fw-bold form-label mb-2">Vesting Duration</label>
									<div class="row fv-row">
										<div class="col-5">
											<input type="text" class="form-control" v-model="contractData.durationUnit" required placeholder="Number" @change="validateVesting" :disabled="unlockFrequency==0" />
										</div>
										<div class="col-7">
											<select name="duration" class="form-select" @change="validateVesting" v-model="contractData.durationTime" :disabled="unlockFrequency==0" >
												<!-- <option value="1">Second</option>
												<option value="60">Minute</option>
												<option value="3600">Hour</option> -->
												<option value="86400">Day</option>
												<option value="604800">Week</option>
												<option value="2628002" selected>Month</option>
												<option value="7884006">Quarter</option>
												<option value="31536000">Year</option>
											</select>
										</div>
										
									</div>
								</div>
								<div class="col-md-4 fv-row">
									<label class="required fs-6 fw-bold form-label mb-2">Cliff</label>
									<div class="row fv-row">
											<div class="input-group">
												<input type="number" 
													class="form-control" 
													v-model="contractData.cliffUnit" 
													required 
													min="0"
													placeholder="Number" 
													@change="validateVesting"
													:disabled="unlockFrequency<=0"
												/>
												<span class="input-group-text">{{DURATION[contractData.durationTime]}}</span>
											</div>
									</div>
								</div>
								
							</div>
							<div class="row mb-0">
								<div class="alert alert-light-primary">
									<i class="fas fa-info-circle"></i> 
									<span v-if="unlockFrequency == -1">
										All tokens will be unlocked after 
										<span class="badge badge-light-primary" v-if="contractData.cliffUnit>0">
											{{contractData.cliffUnit}} {{DURATION[contractData.durationTime]}} (cliff)
										</span> 
										<span v-if="contractData.cliffUnit>0">+</span> 
										<span class="badge badge-light-primary">
											{{contractData.durationUnit}} {{DURATION[contractData.durationTime]}} (vesting)
										</span>
									</span>
									<span v-else-if="unlockFrequency == 0">
										All recipients can claim their tokens once contract is started
									</span>
									<span v-else>
										Tokens can be claimed 
										<span class="badge badge-light-primary">{{SCHEDULE[contractData.unlockSchedule]}}</span> 
										over <span class="badge badge-light-primary">{{contractData.durationUnit}} {{DURATION[contractData.durationTime]}}</span>
										<span v-if="contractData.cliffUnit>0">
											after <span class="badge badge-light-primary">{{contractData.cliffUnit}} {{DURATION[contractData.durationTime]}} cliff period</span>
										</span>
									</span>
								</div>
							</div>

						</div>
					</div>
				</div>
			</div>
			<div class="col-md-5 fv-row">
				<div class="card card-xl-stretch mb-xl-8">
					<div class="card-header align-items-center">
						<label class="fs-4 fw-bold form-label mb-2 text-primary">Vesting Schedule</label>
					</div>
					<div class="card-body pt-5 pb-2">
						<VestingChart :contractInfo="contractDataComputed"></VestingChart>
						<!-- <PreviewChart :contractInfo="contractDataComputed"></PreviewChart> -->
						<!-- <div class="d-flex align-items-center mb-3">
							<div class="flex-grow-1">
								<span class="text-gray-800 text-hover-primary fw-bold fs-6">Vesting duration</span>
							</div>
							<span class="badge badge-secondary fs-8 fw-bolder">
								{{contractData.durationUnit}} {{DURATION[contractData.durationTime]}}
							</span>
						</div>
						<div class="d-flex align-items-center mb-3">
							<div class="flex-grow-1">
								<span class="text-gray-800 text-hover-primary fw-bold fs-6">Cliff</span>
							</div>
							<span class="badge badge-secondary fs-8 fw-bolder">
								{{contractData.cliffUnit}} {{DURATION[contractData.cliffTime]}}
							</span>
						</div>
						<div class="d-flex align-items-center mb-5">
							<div class="flex-grow-1">
								<span class="text-gray-800 text-hover-primary fw-bold fs-6">Unlock schedule</span>
							</div>
							<span class="badge badge-secondary fs-8 fw-bolder">
								{{SCHEDULE[contractData.unlockSchedule]}}
							</span>
						</div> -->
					</div>
				</div>
			</div>
		</div>
	
	<div class="card mb-xl-8" >
		<div class="card-header align-items-center">
			<h3 class="card-title align-items-start flex-column">
				<div class="card-label fw-bolder fs-3 mb-1">
					<label class="form-check-label" for="whitelistDistribution" title="Switch distribution type">
						<span v-if="whitelistDistribution">Whitelist</span>
						<span v-else>Public</span>
						distribution
					</label>
				</div>
				<div class="text-gray mt-1 fw-bold fs-7">
					<span v-if="whitelistDistribution">Only recipients in the list will receive/claim tokens</span>
					<span v-else>Any user can claim tokens if contract is public</span>
				</div>
			</h3>
			<div class="card-toolbar">
				<div class="d-flex">
					<div class="fw-bolder fs-2 text-primary px-10">
						{{currencyFormat(tokenBalance)}}
						<span class="text-muted fs-4 fw-bold">{{tokenInfo.symbol}}</span>
						<div class="fs-7 fw-normal text-muted">
							Your balance
							<LoadingLabel 
										:loading="isLoading"
										class="badge badge-light-primary ms-5"
										@click="getTokenBalance"><i class="fas fa-arrows-rotate"></i> Refresh
							</LoadingLabel>
						</div>
					</div>
					<div class="fw-bolder fs-2 text-success px-10">
						{{currencyFormat((tokenBalance - contractData.totalAmount > 0?(tokenBalance - contractData.totalAmount):0))}}
						<span class="text-muted fs-4 fw-bold">{{tokenInfo.symbol}}</span>
						<div class="fs-7 fw-normal text-muted">Remaining amount</div>
					</div>
					<div class="fw-bolder fs-2 text-danger px-10">
						{{currencyFormat(contractData.totalAmount)}}
						<span class="text-muted fs-4 fw-bold">{{tokenInfo.symbol}}</span>
						<div class="fs-7 fw-normal text-muted">Will be sent</div>
					</div>
				</div>
			</div>

		</div>
		<div class="card-body pt-5 pb-2" v-if="!whitelistDistribution">
			<div class="row mb-3">
				<div class="col-md-3 fv-row">
					<label class="required fs-6 fw-bold form-label mb-2">Total recipients</label>
					<div class="row">
						<div class="col-12">
							<input type="number" class="form-control form-control-sm" v-model="totalRecipient" min="0" placeholder="0" @change="calculateTokenPerRecipient">
						</div>
					</div>
				</div>
				<div class="col-md-3">
					<label class="required fs-6 fw-bold form-label mb-2">Total {{tokenInfo.symbol}} spent</label>
					<div class="row fv-row">
						<div class="col-12">
							<input type="number" class="form-control form-control-sm" v-model="contractData.totalAmount" min="0" placeholder="0" @change="calculateTokenPerRecipient">
						</div>
					</div>
				</div>
				<div class="col-md-3">
					<label class="required fs-6 fw-bold form-label mb-2">{{tokenInfo.symbol}} per recipient</label>
					<div class="row fv-row">
						<div class="col-12">
							<input type="number" class="form-control form-control-sm" v-model="tokenPerRecipient" min="0" placeholder="0" disabled>
						</div>
					</div>
				</div>
				
				<div class="col-md-3">
					<label class="required fs-6 fw-bold form-label mb-2">Distribution method</label>
					<div class="row fv-row">
						<div class="col-12">
							<select name="distributionMethod" class="form-control-sm form-select form-select-sm" readonly>
								<option value="0" selected>First come first serve</option>
							</select>
						</div>
					</div>
				</div>
			</div>
			<div class="row">
				<div class="col-md-12">
					<div class="alert alert-info">
						<i class="fas fa-info-circle text-info"></i> 
						<span> We recommend enabling BlockID and set a minimum score to prevent malicious users/bots from claiming tokens at settings section
						</span>
					</div>
				</div>
			</div>
		</div>
		<div class="card-body pt-5 pb-2" v-else>
			<h3 class="card-title align-items-start flex-column flex">
				<div class="card-label fw-bolder fs-3 mb-1">
					Recipients <span class="badge badge-light-primary">{{recipients.length}}</span>
				</div>
				<div class="text-muted mt-1 fw-bold fs-7 card-toolbar">
					<div class="form-check form-switch form-check-custom form-check-solid">
						<input class="form-check-input  h-20px w-30px" type="checkbox" value="true" id="flexSwitchChecked" v-model="contractData.editorMode" @click="switchMode" />
						<label class="form-check-label" for="flexSwitchChecked" title="Switch to code edit">
							Editor mode
						</label>
					</div>
				</div>
			</h3>
			<div v-if="contractData.editorMode">
				<Codemirror
					v-model:value="recipientsEdit"
					:options="cmOptions"
					border
					placeholder=""
					:height="200"
					@change="checkingRecipients"
					ref="codemirror"
				/>
				<div class="d-flex flex-wrap w-100">
					<div class="flex-grow-1"><strong>Format: </strong>principal,amount,note (opt) | <span class="text-danger">Maximum: 200 recipients</span></div>
					<div class="">
						<a href="javascript:void(0);" @click="loadSampleData()">Load sample data</a>
					</div>
				</div>
			</div>
			<div class="table-responsive border-bottom mb-5 border table-rounded" v-if="!contractData.editorMode">
				<table class="table align-middle gs-0 table-row-dashed fs-6 gy-2 mb-0 table-hover">
					<thead>
						<tr class="fw-bolder fs-7 text-gray-800 border-bottom border-gray-200 bg-light">
							<th class="ps-4 w-25px ">#</th>
							<th class="min-w-400px">Principal ID</th>
							<th class="w-150px text-end">Amount</th>
							<th class="min-w-100px">Note</th>
							<th class="w-100px text-end"></th>
						</tr>
					</thead>
					<thead>
						<tr class="bg-light fw-bolder">
							<td class="text-center fs-7">
								
							</td>
							<td>
								<input type="text" class="form-control form-control-sm d-block" v-model="newRecipient.address" placeholder="Enter Principal ID" ref="address">
							</td>
							<td>
								<input type="number" class="form-control form-control-sm text-red text-end" v-model="newRecipient.amount" min="0" placeholder="0">
							</td>
							<td>
								<span class="text-muted fw-bold text-muted d-block fs-7">
									<input type="text" class="form-control d-block form-control-sm"  v-model="newRecipient.note" placeholder="Note (Option)">
								</span>
							</td>
							<td class="text-end">
								<button type="button" class="btn btn-primary d-block btn-sm px-4 me-2" @click="addRecipient()"> Add <i class="fas fa-plus fs-7"></i> </button>
							</td>
						</tr>
					</thead>
					<tbody>
						<tr v-if="recipients.length == 0">
							<td colspan="6" class="bg-white p-5">
								<div class="fw-bold text-muted p-2">No recipient, or do you want to create <a href="javascript:void(0);" @click="whitelistDistribution=false">public distribution contract?</a></div>
							</td>
						</tr>
						<tr v-else v-for="(recipient, idx) in recipients">
							<td class="text-center ps-4">
								{{idx+1}}.
							</td>
							<td>
								<span class="text-muted fw-bold text-gray-800 d-block fs-7">
									<ClickToCopy :text="recipient.address">{{recipient.address}}</ClickToCopy>
								</span>
							</td>
							<td>
								<span class="text-muted fw-bold text-gray-800 d-block fs-7 text-end">
									{{currencyFormat(recipient.amount)}} {{tokenInfo.symbol.toUpperCase()}}
								</span>
							</td>
							<td>
								<span class="fw-bold text-gray-800 d-block fs-7">
									{{recipient.note}}
								</span>
							</td>
							<td class="text-center">
								<button type="button" title="Remove" class="btn btn-icon btn-danger btn-sm  h-20px w-20px" @click="removeRecipient(idx)">
									<i class="fas fa-trash"></i>
								</button>
							</td>
						</tr>
					</tbody>
					<tfoot>
						<tr class="fw-bolder fs-7 text-gray-800 border-bottom border-gray-200 bg-light">
							<th class="ps-4 w-25px">#</th>
							<th class="min-w-400px">Principal ID</th>
							<th class="w-150px text-end">Amount</th>
							<th class="min-w-100px">Note</th>
							<th class="w-100px text-end"></th>
						</tr>
					</tfoot>
				</table>
			</div>
			<div class="row mt-3">
				<div class="col-md-12">
					<div class="alert alert-info">
						<i class="fas fa-info-circle text-info"></i> 
						<span> If you want to distribute tokens to a large number of recipients, please use the <a href="javascript:void(0);" @click="switchMode">editor mode</a> to enter the recipients' information</span>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="card mb-xl-8">
		<div class="card-header align-items-center">
			<label class="fs-4 fw-bold form-label mb-2 text-primary">Settings</label>
		</div>
		<div class="card-body pt-5">
			<div class="row mb-5">
				<div class="col-md-12 fv-row mb-4">
					<label class="form-check form-switch form-check-custom form-check-solid">
						<input class="form-check-input h-20px w-30px" type="checkbox" v-model="contractData.allowCancel"/>
						<span :class="`form-check-label fw-bold ${contractData.allowCancel?'':'text-muted'}`">Allow the owner to cancel, remaining tokens will be transfered to the owner</span>
					</label>
				</div>
				<div class="col-md-12 fv-row mb-4" v-if="whitelistDistribution">
					<label class="form-check form-switch form-check-custom form-check-solid">
						<input class="form-check-input h-20px w-30px" type="checkbox" v-model="contractData.autoTransfer"/>
						<span class="form-check-label fw-bold " v-if="contractData.autoTransfer">Auto transfer token to recipients when unlocked</span>
						<span class="form-check-label fw-bold text-muted" v-else>Recipient request claim manually</span>
					</label>
					<span class="fs-7 text-danger">The smart contract will automatically send tokens to the recipients' wallets once the vesting period is reached. This feature will consume more Cycles than usual.</span>
				</div>
				<div class="col-md-12 fv-row mb-4" v-if="!whitelistDistribution">
					<label class="form-check form-switch form-check-custom form-check-solid">
						<input class="form-check-input h-20px w-30px" type="checkbox" v-model="contractData.useBlockId" :disabled="whitelistDistribution"/>
						<span :class="`form-check-label fw-bold ${contractData.useBlockId?'':'text-muted'}`">Require BlockID score to claim</span>
					</label>
					<div class="d-flex mt-2" v-if="contractData.useBlockId">
						<div class="">
							<input type="number" class="form-control form-control-sm text-end w-20" placeholder="0" v-model="contractData.blockId" min="0"/>
						</div>
						<div class="pt-2 ps-2">
							<span class="form-check-label fs-7 ">Define the BlockID score, 0 for disable. <a href="https://docs.icto.app/block-id/about" target="_blank">What is BlockID?</a></span>
						</div>
					</div>
				</div>
				<div class="col-md-4 fv-row mb-4">
					<label class="fs-6 fw-bold form-label mb-2">Start now</label>
					<label class="form-check form-switch form-check-custom form-check-solid">
						<input class="form-check-input h-20px w-30px" type="checkbox" v-model="contractData.startNow"/>
						<span :class="`form-check-label fw-bold ${contractData.startNow?'':'text-muted'}`">Start upon contract creation</span>
					</label>
				</div>
				<div class="col-md-4 fv-row mb-4" v-if="!contractData.startNow">
					<label class="required  fs-6 fw-bold form-label mb-2">Specify start time</label>
					<VueDatePicker v-model="contractData.startTime" :min-date="new Date()" :enable-time-picker="true" time-picker-inline auto-apply></VueDatePicker>
				</div>
			</div>
			
			<div class="d-flex flex-column pe-0">
				<button type="submit" class="btn btn-lg btn-primary btn-block">Preview Contract
					<span class="svg-icon svg-icon-3 ms-1 me-0">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
							<rect opacity="0.5" x="18" y="13" width="13" height="2" rx="1" transform="rotate(-180 18 13)" fill="black" />
							<path d="M15.4343 12.5657L11.25 16.75C10.8358 17.1642 10.8358 17.8358 11.25 18.25C11.6642 18.6642 12.3358 18.6642 12.75 18.25L18.2929 12.7071C18.6834 12.3166 18.6834 11.6834 18.2929 11.2929L12.75 5.75C12.3358 5.33579 11.6642 5.33579 11.25 5.75C10.8358 6.16421 10.8358 6.83579 11.25 7.25L15.4343 11.4343C15.7467 11.7467 15.7467 12.2533 15.4343 12.5657Z" fill="black" />
						</svg>
					</span>
				</button>
			</div>
		</div>
	</div>
	
</form>

</template>