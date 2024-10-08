export default ({ IDL }) => {
    const Subaccount = IDL.Vec(IDL.Nat8);
    const Balance = IDL.Nat;
    const BurnArgs = IDL.Record({
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'from_subaccount' : IDL.Opt(Subaccount),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const TxIndex = IDL.Nat;
    const Timestamp = IDL.Nat64;
    const TransferError = IDL.Variant({
      'GenericError' : IDL.Record({
        'message' : IDL.Text,
        'error_code' : IDL.Nat,
      }),
      'TemporarilyUnavailable' : IDL.Null,
      'BadBurn' : IDL.Record({ 'min_burn_amount' : Balance }),
      'Duplicate' : IDL.Record({ 'duplicate_of' : TxIndex }),
      'BadFee' : IDL.Record({ 'expected_fee' : Balance }),
      'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
      'TooOld' : IDL.Null,
      'InsufficientFunds' : IDL.Record({ 'balance' : Balance }),
    });
    const TransferResult = IDL.Variant({ 'Ok' : TxIndex, 'Err' : TransferError });
    const TxIndex__2 = IDL.Nat;
    const Account = IDL.Record({
      'owner' : IDL.Principal,
      'subaccount' : IDL.Opt(Subaccount),
    });
    const Burn = IDL.Record({
      'from' : Account,
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const Mint__1 = IDL.Record({
      'to' : Account,
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const Transfer = IDL.Record({
      'to' : Account,
      'fee' : IDL.Opt(Balance),
      'from' : Account,
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const Transaction__1 = IDL.Record({
      'burn' : IDL.Opt(Burn),
      'kind' : IDL.Text,
      'mint' : IDL.Opt(Mint__1),
      'timestamp' : Timestamp,
      'index' : TxIndex,
      'transfer' : IDL.Opt(Transfer),
    });
    const GetTransactionsRequest = IDL.Record({
      'start' : TxIndex,
      'length' : IDL.Nat,
    });
    const Transaction = IDL.Record({
      'burn' : IDL.Opt(Burn),
      'kind' : IDL.Text,
      'mint' : IDL.Opt(Mint__1),
      'timestamp' : Timestamp,
      'index' : TxIndex,
      'transfer' : IDL.Opt(Transfer),
    });
    const GetTransactionsRequest__1 = IDL.Record({
      'start' : TxIndex,
      'length' : IDL.Nat,
    });
    const TransactionRange = IDL.Record({
      'transactions' : IDL.Vec(Transaction),
    });
    const QueryArchiveFn = IDL.Func(
        [GetTransactionsRequest__1],
        [TransactionRange],
        ['query'],
      );
    const ArchivedTransaction = IDL.Record({
      'callback' : QueryArchiveFn,
      'start' : TxIndex,
      'length' : IDL.Nat,
    });
    const GetTransactionsResponse = IDL.Record({
      'first_index' : TxIndex,
      'log_length' : IDL.Nat,
      'transactions' : IDL.Vec(Transaction),
      'archived_transactions' : IDL.Vec(ArchivedTransaction),
    });
    const Account__2 = IDL.Record({
      'owner' : IDL.Principal,
      'subaccount' : IDL.Opt(Subaccount),
    });
    const Balance__2 = IDL.Nat;
    const Value = IDL.Variant({
      'Int' : IDL.Int,
      'Nat' : IDL.Nat,
      'Blob' : IDL.Vec(IDL.Nat8),
      'Text' : IDL.Text,
    });
    const MetaDatum = IDL.Tuple(IDL.Text, Value);
    const SupportedStandard = IDL.Record({ 'url' : IDL.Text, 'name' : IDL.Text });
    const TransferArgs = IDL.Record({
      'to' : Account,
      'fee' : IDL.Opt(Balance),
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'from_subaccount' : IDL.Opt(Subaccount),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const Account__1 = IDL.Record({
      'owner' : IDL.Principal,
      'subaccount' : IDL.Opt(Subaccount),
    });
    const AllowanceArgs = IDL.Record({
      'account' : Account__1,
      'spender' : Account__1,
    });
    const Allowance = IDL.Record({
      'allowance' : IDL.Nat,
      'expires_at' : IDL.Opt(IDL.Nat64),
    });
    const Balance__1 = IDL.Nat;
    const Memo = IDL.Vec(IDL.Nat8);
    const Subaccount__1 = IDL.Vec(IDL.Nat8);
    const ApproveArgs = IDL.Record({
      'fee' : IDL.Opt(Balance__1),
      'memo' : IDL.Opt(Memo),
      'from_subaccount' : IDL.Opt(Subaccount__1),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance__1,
      'expected_allowance' : IDL.Opt(IDL.Nat),
      'expires_at' : IDL.Opt(IDL.Nat64),
      'spender' : Account__1,
    });
    const ApproveError = IDL.Variant({
      'GenericError' : IDL.Record({
        'message' : IDL.Text,
        'error_code' : IDL.Nat,
      }),
      'TemporarilyUnavailable' : IDL.Null,
      'Duplicate' : IDL.Record({ 'duplicate_of' : TxIndex }),
      'BadFee' : IDL.Record({ 'expected_fee' : Balance }),
      'AllowanceChanged' : IDL.Record({ 'current_allowance' : IDL.Nat }),
      'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
      'TooOld' : IDL.Null,
      'Expired' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
      'InsufficientFunds' : IDL.Record({ 'balance' : Balance }),
    });
    const ApproveResult = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : ApproveError });
    const TransferFromArgs = IDL.Record({
      'to' : Account__1,
      'fee' : IDL.Opt(Balance__1),
      'spender_subaccount' : IDL.Opt(Subaccount__1),
      'from' : Account__1,
      'memo' : IDL.Opt(Memo),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance__1,
    });
    const TxIndex__1 = IDL.Nat;
    const TransferFromError = IDL.Variant({
      'GenericError' : IDL.Record({
        'message' : IDL.Text,
        'error_code' : IDL.Nat,
      }),
      'TemporarilyUnavailable' : IDL.Null,
      'InsufficientAllowance' : IDL.Record({ 'allowance' : IDL.Nat }),
      'BadBurn' : IDL.Record({ 'min_burn_amount' : Balance }),
      'Duplicate' : IDL.Record({ 'duplicate_of' : TxIndex }),
      'BadFee' : IDL.Record({ 'expected_fee' : Balance }),
      'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
      'TooOld' : IDL.Null,
      'InsufficientFunds' : IDL.Record({ 'balance' : Balance }),
    });
    const TransferFromResult = IDL.Variant({
      'Ok' : TxIndex__1,
      'Err' : TransferFromError,
    });
    const Mint = IDL.Record({
      'to' : Account,
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    return IDL.Service({
      'burn' : IDL.Func([BurnArgs], [TransferResult], []),
      'deposit_cycles' : IDL.Func([], [], []),
      'get_transaction' : IDL.Func([TxIndex__2], [IDL.Opt(Transaction__1)], []),
      'get_transactions' : IDL.Func(
          [GetTransactionsRequest],
          [GetTransactionsResponse],
          ['query'],
        ),
      'icrc1_balance_of' : IDL.Func([Account__2], [Balance__2], ['query']),
      'icrc1_decimals' : IDL.Func([], [IDL.Nat8], ['query']),
      'icrc1_fee' : IDL.Func([], [Balance__2], ['query']),
      'icrc1_metadata' : IDL.Func([], [IDL.Vec(MetaDatum)], ['query']),
      'icrc1_minting_account' : IDL.Func([], [IDL.Opt(Account__2)], ['query']),
      'icrc1_name' : IDL.Func([], [IDL.Text], ['query']),
      'icrc1_supported_standards' : IDL.Func(
          [],
          [IDL.Vec(SupportedStandard)],
          ['query'],
        ),
      'icrc1_symbol' : IDL.Func([], [IDL.Text], ['query']),
      'icrc1_total_supply' : IDL.Func([], [Balance__2], ['query']),
      'icrc1_transfer' : IDL.Func([TransferArgs], [TransferResult], []),
      'icrc2_allowance' : IDL.Func([AllowanceArgs], [Allowance], ['query']),
      'icrc2_approve' : IDL.Func([ApproveArgs], [ApproveResult], []),
      'icrc2_transfer_from' : IDL.Func(
          [TransferFromArgs],
          [TransferFromResult],
          [],
        ),
      'mint' : IDL.Func([Mint], [TransferResult], []),
    });
  };
  export const init = ({ IDL }) => { return []; };