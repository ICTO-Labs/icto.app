
dfx deploy "claim_contract" --argument "(
    record {
        \"title\" = \"Claim Test Tokens for Test Phase 2\";
        \"description\" = \"You can claim tICP (Test ICP) to paticipate in Launchpad. Once you have your tICP tokens, you can connect your wallet to Launchpad and start participating in the platform. This contract is protected by BlockID to ensure the integrity of the distribution process.\";
        \"durationTime\" = 60;
        \"durationUnit\" = 0;
        \"cliffTime\" = 60;
        \"cliffUnit\" = 5;
        \"unlockSchedule\" = 60;
        \"canCancel\" = \"neither\";
        \"canChange\"= \"neither\";
        \"canView\" = \"neither\";
        \"startNow\" = true;
        \"startTime\" = 1729864800000;
        \"created\"= 17298571290000;
        \"maxRecipients\"= 1000;
        \"totalAmount\"= 10000000000000;
        \"distributionType\"= \"FirstComeFirstServed\";
        \"tokenInfo\"= record {
            \"canisterId\"= \"3mj2l-5aaaa-aaaap-qkmfq-cai\";
            \"name\"= \"Test ICP\";
            \"symbol\"= \"tICP\";
            \"standard\"= \"ICRC2\";
            \"decimals\"= 8;
            \"fee\"= 10000;
        };
        \"recipients\"= opt vec { record { \"address\"= \"lekqg-fvb6g-4kubt-oqgzu-rd5r7-muoce-kppfz-aaem3-abfaj-cxq7a-dqe\"; \"amount\"= 10_000_000_000; \"note\"= opt \"Developer\"; }; record { \"address\"= \"v57dj-hev4p-lsvdl-dckvv-zdcvg-ln2sb-tfqba-nzb4g-iddrv-4rsq3-mae\"; \"amount\"= 15_900_000_000; \"note\"= opt \"Marketing\"; }; };
        \"owner\"= principal \"lekqg-fvb6g-4kubt-oqgzu-rd5r7-muoce-kppfz-aaem3-abfaj-cxq7a-dqe\"
    }
)" --mode reinstall --network ic
