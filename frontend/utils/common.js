import { useToast } from 'vue-toastification'
const toast = useToast()

import {Principal} from "@dfinity/principal";
import {Buffer} from "buffer";
import { sha224 } from '@dfinity/principal/lib/esm/utils/sha224';
import { getCrc32 } from '@dfinity/principal/lib/esm/utils/getCrc';
import EventBus from "@/services/EventBus";

import RosettaApi from '@/services/RosettaApi';
import moment from 'moment/moment';
const rosettaApi = new RosettaApi();

export const getAccountBalance = async(address)=>{
    return await rosettaApi.getAccountBalance(address);
}
const isHex = (h) => {
    var regexp = /^[0-9a-fA-F]+$/;
    return regexp.test(h);
};
export const showModal = (key, data)=>{
    EventBus.emit(key, data);
}
export const toHexString = (byteArray)  =>{
    return Array.from(byteArray, function(byte) {
        return ('0' + (byte & 0xFF).toString(16)).slice(-2);
    }).join('')
}
export const validatePrincipal = (p) => {
    try {
        return (p === Principal.fromText(p).toText());
    } catch (e) {
        return false;
    }
}
const isPrincipal = (p)=>{
    return !!p && p._isPrincipal;
}
export const isAnonymous = (p)=>{
    return p == "2vxsx-fae";
}
export const principalToText = (p)=>{
    if(isPrincipal(p)){
        return p.toText();
    }else{
        return p;
    }
}
export const validateAddress = (a) => {
    return (isHex(a) && a.length === 64)
}
export const showError = (message, useSwal=false, useHTML=false)=>{
    if(useSwal){
        var _obj = {icon: 'error', title: 'Error!', text: message};
        if(useHTML){
            _obj = {icon: 'error', title: 'Error!', html: message};
        }
        Swal.fire(_obj);
    }else{
        toast.error(message);
    }
    
}
export const clearToast = ()=>{
    // toast.clearAll();
}
export const showSuccess = (message, useSwal=false)=>{
    if(useSwal){
        Swal.fire({
            icon: 'success',
            title: 'Successful!',
            text: message
        })
    }else{
        toast.success(message);
    }
}
export const showLoading = (message)=>{
    window.Swal.fire({
        html: message,
        allowEscapeKey: false,
        allowOutsideClick: false,
        showConfirmButton: false,
        didOpen: () => {
            window.Swal.showLoading()
        }
    });
}
export const closeMessage = ()=>{
    Swal.close();
}
const to32bits = (num) => {
    let b = new ArrayBuffer(4)
    new DataView(b).setUint32(0, num)
    return Array.from(new Uint8Array(b))
  }
export const txtToPrincipal = (p)=>{
    try {
        return Principal.fromText(p);
    } catch (e) {
        return p;
    }
}  
export const principalToAccountId = (p, s) => {
    if(!p) return p;
    let _p = principalToText(p);
    const padding = Buffer("\x0Aaccount-id");
    const array = new Uint8Array([
        ...padding,
        ...Principal.fromText(_p).toUint8Array(),
        ...getSubAccountArray(s)
    ]);
    const hash = sha224(array);
    const checksum = to32bits(getCrc32(hash));
    const array2 = new Uint8Array([
        ...checksum,
        ...hash
    ]);
    return toHexString(array2);
};
export const getSubAccountArray = (s) => {
    if (Array.isArray(s)){
        return s.concat(Array(32-s.length).fill(0));
    } else {
        //32 bit number only
        return Array(28).fill(0).concat(to32bits(s ? s : 0))
    }
};
const from32bits = ba => {
    var value;
    for (var i = 0; i < 4; i++) {
        value = (value << 8) | ba[i];
    }
    return value;
}
export const shortAccount = (accountId)=>{
   if(!accountId) return accountId;
  return `${accountId.slice(0, 8)}...${accountId.slice(-8)}`;
}
export const shortPrincipal = (principal) => {
    if(!principal) return principal;
  const parts = (
    typeof principal === "string" ? principal : principal.toText()
  ).split("-");
  return `${parts[0]}...${parts.slice(-1)[0]}`;
};
function deepCopy(text) {
    var textArea = document.createElement("textarea");
    textArea.value = text;
    // Avoid scrolling to bottom
    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.position = "fixed";

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
        var successful = document.execCommand('copy');
        var msg = successful ? 'successful' : 'unsuccessful';
        console.log('Fallback: Copying text command was ' + msg);
    } catch (err) {
        console.error('Fallback: Oops, unable to copy', err);
    }

    document.body.removeChild(textArea);
}
export const copyToClipboard = (text, item) => {
    if (!navigator.clipboard) {
        deepCopy(text);
        return;
    }
    navigator.clipboard.writeText(text).then(function() {
        // toast.clear();
        // toast.info(item+' copied!');
        console.log('Async: Copying to clipboard was successful!');
    }, function(err) {
        console.error('Async: Could not copy text: ', err);
    });
}
export const getRandomBytes = () => {
    var bs = [];
    for (let i = 0; i < 32; i++) {
        bs.push(Math.floor(Math.random() * 256));
    }
    return bs;
};

export const prettyValue = (value, replace)=>{
    if(typeof value === "undefined"){
        return replace;
    }else{
        return value;
    }
}

//Format time to UTC, bigint
export const timeFromNano = (nanoseconds)=>{
    return moment.unix(Number(nanoseconds)/1e9).format('YYYY-MM-DD HH:mm:ss');
}
export const getPoolStatus = (status)=>{
    console.log('status', status);
        let text, colorClass;
        switch (status) {
        case 'UPCOMING':
            text = 'Not Started';
            colorClass = 'primary';
            break;
        case 'LIVE':
            text = 'Live';
            colorClass = 'success';
            break;
        case 'FINISHED':
            text = 'Finished';
            colorClass = 'info';
            break;
        case 'CLAIMING':
            text = 'Claiming';
            colorClass = 'warning';
            break;
        case 'REFUNDING':
            text = 'Refunding';
            colorClass = 'danger';
            break;
        default:
            text = 'Unknown';
            colorClass = 'muted';
        }
        return `<div class="badge badge-light-${colorClass} text-${colorClass} fs-7 fw-bold">${status == 'LIVE'?'<div class="bullet bg-success bullet-dot me-1 h-10px w-10px animation-blink"></div>':''} ${status}</div>`;
    }

export const saveRef = (ref) => {
    if(ref){
        localStorage.setItem('refCode', ref);
    }
}
export const getRef = () => {
    let _ref = localStorage.getItem('refCode');
    if(_ref){
        return [_ref];
    }else{
        return [];
    }
}
export const getTimeFromNano = (nanoseconds)=>{
    return moment.unix(Number(nanoseconds)/1e9).format('lll');
}
export const getTimeFromNanoToSeconds = (nanoseconds)=>{
    return Number(nanoseconds)/1e9;
}
export const getVariantType = (variant) => {
    try{
        return Object.keys(variant)[0];
    }catch(e){
        return '---';
    }
}
export const cycleFormat = (cycle) => {
    return (Number(cycle)/1e12).toFixed(2) + ' T';
}
export default {
    validateAddress,
    showError
}