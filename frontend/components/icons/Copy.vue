<script>
    import {copyToClipboard} from "@/utils/common.js";
    export default {
        props: ['text', 'item'],
        data(){
            return{
                isCopied: false
            }
        },
        methods: {
            async copyToClipboard(){
                copyToClipboard(this.text, this.item);
                this.changeCopyBtn();
            },
            changeCopyBtn(){
                this.isCopied = true;
                setInterval(()=>{
                    this.isCopied = false;
                }, 3000)
            }
        }
    };

</script>
<template>
    <button href="javascript:void(0)" @click.stop="copyToClipboard()" title="Copy" class="btn btn-active-color-primary btn-icon btn-sm btn-outline-light btn-auto">
        <span :class="`svg-icon svg-icon-2 ${isCopied?'d-none':''}`">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path opacity="0.5" d="M18 2H9C7.34315 2 6 3.34315 6 5H8C8 4.44772 8.44772 4 9 4H18C18.5523 4 19 4.44772 19 5V16C19 16.5523 18.5523 17 18 17V19C19.6569 19 21 17.6569 21 16V5C21 3.34315 19.6569 2 18 2Z" fill="black"></path>
                <path fill-rule="evenodd" clip-rule="evenodd" d="M14.7857 7.125H6.21429C5.62255 7.125 5.14286 7.6007 5.14286 8.1875V18.8125C5.14286 19.3993 5.62255 19.875 6.21429 19.875H14.7857C15.3774 19.875 15.8571 19.3993 15.8571 18.8125V8.1875C15.8571 7.6007 15.3774 7.125 14.7857 7.125ZM6.21429 5C4.43908 5 3 6.42709 3 8.1875V18.8125C3 20.5729 4.43909 22 6.21429 22H14.7857C16.5609 22 18 20.5729 18 18.8125V8.1875C18 6.42709 16.5609 5 14.7857 5H6.21429Z" fill="black"></path>
            </svg>
        </span>
        <i v-if="isCopied" class="fas fa-check"></i>
    </button>
</template>
<style>
    .copy{
        cursor: pointer;
        font-size: 12px;
    }
    .copy:hover{
        color: #009ef7;
    }
</style>