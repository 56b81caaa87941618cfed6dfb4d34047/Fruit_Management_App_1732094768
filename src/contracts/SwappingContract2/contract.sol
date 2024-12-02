
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

library Errors {
    error InvalidAddress();
    error CallbackClientAddressShouldBeMsgSender();
    error CallerIsNotTrustedRelayer();
    error ValueExceedsUint248Limit();
    error InvalidQueryID();
    error InvalidQueryHashOrID();
    error VerificationSignatureRequired();
    error InvalidVerificationSignature();
    error QueryTimeout();
    error NotSupportedMethod();
}

library DataTypes {
    enum PaymentType {
        BuyCredit,
        OnDemandQuery
    }

    struct PaymentAssetAcceptedMethod {
        bool buyCredit;
        bool onDemandQuery;
    }

    enum SolidityType {
        Int256,
        Uint256,
        Address,
        Bytes,
        String
    }

    enum QueryType {
        SQL,
        SavedSQLQueryJobId,
        AST
    }

    enum ZKVerification {
        External,
        None
    }

    struct QueryResult {
        bytes32 queryHash;
        uint64 executionTimestamp;
        Column[] columns;
    }

    struct Column {
        string name;
        SolidityType solidityType;
        bytes[] values;
    }

    struct QueryParameter {
        SolidityType solidityType;
        bytes value;
    }

    struct QueryData {
        bytes query;
        QueryType queryType;
        QueryParameter[] queryParameters;
        uint64 timeout;
        address callbackClientContractAddress;
        uint64 callbackGasLimit;
        bytes callbackData;
        ZKVerification zkVerficiation;
    }

    struct QueryPayment {
        address asset;
        uint248 amount;
        address source;
    }

    struct ZKpayError {
        bytes32 queryHash;
        uint8 code;
        string message;
    }
}

interface IZKPayClient {
    function sxtCallback(
        DataTypes.QueryResult calldata queryResult,
        bytes calldata callbackData,
        DataTypes.ZKVerification zKVerification
    ) external;

    function sxtErrorCallback(DataTypes.ZKpayError calldata error, bytes calldata callbackData) external;
}

interface IZKPay {
    event TreasurySet(address indexed newTreasury);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event TrustedRelayerAdded(address indexed relayer);
    event TrustedRelayerRemoved(address indexed relayer);
    event AcceptedAssetSet(address indexed asset, bool buyCredit, bool onDemandPayments);
    event NewQueryPayment(bytes32 indexed queryHash, address indexed asset, uint248 amount, address indexed source);
    event QueryFulfilled(bytes32 indexed queryHash, address indexed prover);
    event QueryReceived(
        uint248 indexed queryId,
        address indexed sender,
        bytes query,
        DataTypes.QueryType queryType,
        bytes queryParamsblob,
        uint64 timeout,
        address callbackClientContractAddress,
        uint64 callbackGasLimit,
        bytes callbackData,
        DataTypes.ZKVerification zkVerification,
        bytes32 queryHash
    );
    event QueryErrorHandled(bytes32 indexed queryHash, uint8 code, string message);

    function setTreasury(address newTreasury) external;
    function addVerifier(address verifier) external;
    function removeVerifier(address verifier) external;
    function addTrustedRelayer(address relayer) external;
    function removeTrustedRelayer(address relayer) external;
    function getTreasury() external view returns (address);
    function getLatestQueryId() external view returns (uint248);
    function getQueryPayment(bytes32 queryHash) external view returns (DataTypes.QueryPayment memory);
    function getQueryIdByHash(bytes32 queryHash) external view returns (uint248);
    function isVerifier(address verifier) external view returns (bool);
    function isTrustedRelayer(address relayer) external view returns (bool);
    function getAcceptedAssetMethod(address asset) external view returns (DataTypes.PaymentAssetAcceptedMethod memory);
    function setAcceptedAsset(address asset, bool buyCredit, bool onDemandPayments) external;
    function isPaymentAssetSupported(address assetAddress, DataTypes.PaymentType paymentType) external view returns (bool);
    function buy(address asset, address from, uint248 amount, address onBehalfOf) external;
    function buyWithNative(address onBehalfOf) external payable;
    function query(DataTypes.QueryData memory queryData) external returns (bytes32);
    function queryWithERC20(address asset, uint248 amount, DataTypes.QueryData memory queryData) external returns (bytes32);
    function queryWithNative(DataTypes.QueryData memory queryData) external payable returns (bytes32);
    function cancelQueryPayment(bytes32 queryHash) external;
    function fulfillQuery(
        uint248 queryId,
        DataTypes.QueryData memory queryData,
        DataTypes.QueryResult memory queryResult,
        bytes calldata verificationSignature,
        uint248 costAmountInPaymentToken,
        address prover,
        DataTypes.ZKpayError calldata error
    ) external;
}


contract ZKPayStorage {
    address internal _treasury;
    uint248 internal _latestQueryId;
    mapping(address asset => DataTypes.PaymentAssetAcceptedMethod) internal _acceptedAssets;
    mapping(bytes32 queryHash => DataTypes.QueryPayment) internal _queryPayments;
    mapping(bytes32 QueryHash => uint248 queryId) internal _queryIdbyHash;
    mapping(address => bool) internal _verifiers;
    mapping(address => bool) internal _trustedRelayers;

    function isVerifier(address verifier) external virtual view returns (bool) {
        return _verifiers[verifier];
    }

    function isTrustedRelayer(address relayer) external virtual view returns (bool) {
        return _trustedRelayers[relayer];
    }

}



contract ZKPay is Initializable, ZKPayStorage, IZKPay, OwnableUpgradeable, EIP712Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address treasury) external initializer {
        __Ownable_init();
        _transferOwnership(admin);
        __EIP712_init("SxT_Verifier", "1");
        _setTreasury(treasury);
    }

    // Admin functions
    function setTreasury(address newTreasury) external override onlyOwner {
        _setTreasury(newTreasury);
    }

    function addVerifier(address verifier) external override onlyOwner {
        _verifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    function removeVerifier(address verifier) external override onlyOwner {
        _verifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }

    function addTrustedRelayer(address relayer) external override onlyOwner {
        _trustedRelayers[relayer] = true;
        emit TrustedRelayerAdded(relayer);
    }

    function removeTrustedRelayer(address relayer) external override onlyOwner {
        _trustedRelayers[relayer] = false;
        emit TrustedRelayerRemoved(relayer);
    }

    // View functions
    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function getLatestQueryId() external view override returns (uint248) {
        return _latestQueryId;
    }

    function getQueryPayment(bytes32 queryHash) external view override returns (DataTypes.QueryPayment memory) {
        return _queryPayments[queryHash];
    }

    function getQueryIdByHash(bytes32 queryHash) external view override returns (uint248) {
        return _queryIdbyHash[queryHash];
    }

    function isVerifier(address verifier) external view override(IZKPay, ZKPayStorage) returns (bool) {
        return _verifiers[verifier];
    }

    function isTrustedRelayer(address relayer) external view override(IZKPay, ZKPayStorage) returns (bool) {
        return _trustedRelayers[relayer];
    }

    function getAcceptedAssetMethod(address asset) external view override returns (DataTypes.PaymentAssetAcceptedMethod memory) {
        return _acceptedAssets[asset];
    }

    function setAcceptedAsset(address asset, bool buyCredit, bool onDemandPayments) external override onlyOwner {
        _acceptedAssets[asset] = DataTypes.PaymentAssetAcceptedMethod({
            buyCredit: buyCredit,
            onDemandQuery: onDemandPayments
        });
        emit AcceptedAssetSet(asset, buyCredit, onDemandPayments);
    }

    function isPaymentAssetSupported(address assetAddress, DataTypes.PaymentType paymentType) external view override returns (bool) {
        if (paymentType == DataTypes.PaymentType.BuyCredit) {
            return _acceptedAssets[assetAddress].buyCredit;
        }
        return _acceptedAssets[assetAddress].onDemandQuery;
    }

    // Payment functions
    function buy(address asset, address from, uint248 amount, address onBehalfOf) external override nonReentrant {
        if (!_acceptedAssets[asset].buyCredit) {
            revert("Asset not accepted for credit purchase");
        }
        IERC20(asset).safeTransferFrom(from, _treasury, amount);
        emit NewQueryPayment(bytes32(0), asset, amount, onBehalfOf);
    }

    function buyWithNative(address onBehalfOf) external payable override nonReentrant {
        if (msg.value > type(uint248).max) revert Errors.ValueExceedsUint248Limit();
        uint248 amount = uint248(msg.value);
        
        if (!_acceptedAssets[address(0)].buyCredit) {
            revert("Native token not accepted for credit purchase");
        }

        (bool success,) = _treasury.call{value: amount}("");
        require(success, "Failed to transfer native token to treasury");
        
        emit NewQueryPayment(bytes32(0), address(0), amount, onBehalfOf);
    }

    // Query functions
    function query(DataTypes.QueryData memory queryData) external override returns (bytes32) {
        return _query(queryData);
    }

    function queryWithERC20(
        address asset,
        uint248 amount,
        DataTypes.QueryData memory queryData
    ) external override returns (bytes32) {
        if (!_acceptedAssets[asset].onDemandQuery) {
            revert("Asset not accepted for on-demand queries");
        }

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        bytes32 queryHash = _query(queryData);
        _queryPayments[queryHash] = DataTypes.QueryPayment({
            asset: asset,
            amount: amount,
            source: msg.sender
        });

        emit NewQueryPayment(queryHash, asset, amount, msg.sender);
        return queryHash;
    }

    function queryWithNative(DataTypes.QueryData memory queryData) external payable override returns (bytes32) {
        if (msg.value > type(uint248).max) revert Errors.ValueExceedsUint248Limit();
        if (!_acceptedAssets[address(0)].onDemandQuery) {
            revert("Native token not accepted for on-demand queries");
        }

        bytes32 queryHash = _query(queryData);
        uint248 amount = uint248(msg.value);

        _queryPayments[queryHash] = DataTypes.QueryPayment({
            asset: address(0),
            amount: amount,
            source: msg.sender
        });

        emit NewQueryPayment(queryHash, address(0), amount, msg.sender);
        return queryHash;
    }

    function cancelQueryPayment(bytes32 queryHash) external override {
        DataTypes.QueryPayment storage payment = _queryPayments[queryHash];
        require(payment.source == msg.sender, "Not the payment source");
        
        if (payment.asset == address(0)) {
            (bool success,) = payment.source.call{value: payment.amount}("");
            require(success, "Failed to refund native token");
        } else {
            IERC20(payment.asset).safeTransfer(payment.source, payment.amount);
        }

        delete _queryPayments[queryHash];
        delete _queryIdbyHash[queryHash];
    }

    function fulfillQuery(
        uint248 queryId,
        DataTypes.QueryData memory queryData,
        DataTypes.QueryResult memory queryResult,
        bytes calldata verificationSignature,
        uint248 costAmountInPaymentToken,
        address prover,
        DataTypes.ZKpayError calldata error
    ) external override {
        if (block.timestamp > queryData.timeout && queryData.timeout != 0) {
            revert Errors.QueryTimeout();
        }

        if (_latestQueryId < queryId) revert Errors.InvalidQueryID();

        bytes32 queryHash = keccak256(abi.encode(queryId, queryData));
        if (_queryIdbyHash[queryHash] != queryId) revert Errors.InvalidQueryHashOrID();

        if (error.code != 0) {
            _handleError(error, queryData, costAmountInPaymentToken);
            return;
        }

        if (queryData.zkVerficiation == DataTypes.ZKVerification.External) {
            if (verificationSignature.length == 0) {
                revert Errors.VerificationSignatureRequired();
            }
            address signer = _validate(queryResult, verificationSignature);
            if (!_verifiers[signer]) revert Errors.InvalidVerificationSignature();
        } else if (queryData.zkVerficiation == DataTypes.ZKVerification.None) {
            if (!_trustedRelayers[msg.sender]) {     // This is line 380
                revert Errors.CallerIsNotTrustedRelayer();
            }
        }

        DataTypes.QueryPayment storage payment = _queryPayments[queryHash];
        if (payment.amount > 0) {
            if (payment.asset == address(0)) {
                (bool success,) = _treasury.call{value: costAmountInPaymentToken}("");
                require(success, "Failed to send cost to treasury");
                
                uint248 refundAmount = payment.amount - costAmountInPaymentToken;
                if (refundAmount > 0) {
                    (success,) = payment.source.call{value: refundAmount}("");
                    require(success, "Failed to refund remaining amount");
                }
            } else {
                IERC20(payment.asset).safeTransfer(_treasury, costAmountInPaymentToken);
                
                uint248 refundAmount = payment.amount - costAmountInPaymentToken;
                if (refundAmount > 0) {
                    IERC20(payment.asset).safeTransfer(payment.source, refundAmount);
                }
            }
        }

        delete _queryPayments[queryHash];
        delete _queryIdbyHash[queryHash];

        IZKPayClient(queryData.callbackClientContractAddress).sxtCallback(
            queryResult,
            queryData.callbackData,
            queryData.zkVerficiation
        );

        emit QueryFulfilled(queryHash, prover);
    }

    // Internal functions
    function _setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) {
            revert Errors.InvalidAddress();
        }
        _treasury = newTreasury;
        emit TreasurySet(newTreasury);
    }

    function _query(DataTypes.QueryData memory queryData) internal returns (bytes32) {
        if (queryData.callbackClientContractAddress != msg.sender) {
            revert Errors.CallbackClientAddressShouldBeMsgSender();
        }

        _latestQueryId += 1;
        bytes32 queryHash = keccak256(abi.encode(_latestQueryId, queryData));
        _queryIdbyHash[queryHash] = _latestQueryId;

        emit QueryReceived(
            _latestQueryId,
            msg.sender,
            queryData.query,
            queryData.queryType,
            abi.encode(queryData.queryParameters),
            queryData.timeout,
            queryData.callbackClientContractAddress,
            queryData.callbackGasLimit,
            queryData.callbackData,
            queryData.zkVerficiation,
            queryHash
        );

        return queryHash;
    }

    function _validate(
        DataTypes.QueryResult memory queryResult,
        bytes calldata signature
    ) internal view returns (address) {
        bytes32 queryResultHash = keccak256(abi.encode(
            queryResult.queryHash,
            queryResult.executionTimestamp,
            queryResult.columns
        ));
        bytes32 digest = _hashTypedDataV4(queryResultHash);
        return ECDSA.recover(digest, signature);
    }

    function _handleError(
        DataTypes.ZKpayError calldata error,
        DataTypes.QueryData memory queryData,
        uint248 costAmountInPaymentToken
    ) internal {
        if (!_trustedRelayers[msg.sender]) revert Errors.CallerIsNotTrustedRelayer();

        DataTypes.QueryPayment storage payment = _queryPayments[error.queryHash];
        if (payment.amount > 0) {
            uint248 refundAmount = payment.amount - costAmountInPaymentToken;
            if (payment.asset == address(0)) {
                (bool success,) = payment.source.call{value: refundAmount}("");
                require(success, "Failed to refund native token");
            } else {
                IERC20(payment.asset).safeTransfer(payment.source, refundAmount);
            }
            
            if (costAmountInPaymentToken > 0) {
                if (payment.asset == address(0)) {
                    (bool success,) = _treasury.call{value: costAmountInPaymentToken}("");
                    require(success, "Failed to send cost to treasury");
                } else {
                    IERC20(payment.asset).safeTransfer(_treasury, costAmountInPaymentToken);
                }
            }
        }

        delete _queryPayments[error.queryHash];
        delete _queryIdbyHash[error.queryHash];

        IZKPayClient(queryData.callbackClientContractAddress).sxtErrorCallback(error, queryData.callbackData);

        emit QueryFulfilled(error.queryHash, msg.sender);
        emit QueryErrorHandled(error.queryHash, error.code, error.message);
    }

    receive() external payable {
        revert Errors.NotSupportedMethod();
    }
}

contract AirdropClient is IZKPayClient {
    using SafeERC20 for IERC20;

    event LogError(uint8 errorCode, string errorMessage);

    address public _owner;
    address public _zkpay;
    IERC20 public immutable _token;
    uint256 public constant AIRDROP_AMOUNT = 150 * 10 ** 18;
    bool public _airdropExecuted;
    bytes32 public _queryHash;

    constructor(address zkpay, address demoToken) {
        _owner = msg.sender;
        _zkpay = zkpay;
        _token = IERC20(demoToken);
        _airdropExecuted = false;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    modifier onlyZKPay() {
        require(msg.sender == _zkpay, "Caller is not _zkpay");
        _;
    }

    modifier onlyOnce() {
        require(!_airdropExecuted, "Airdrop has already been executed");
        _;
        _airdropExecuted = true;
    }

    function queryZKPay() external payable onlyOwner {
        DataTypes.QueryParameter[] memory queryParams;

        DataTypes.QueryData memory queryData = DataTypes.QueryData({
            query: abi.encode(
                "SELECT FROM_ADDRESS, COUNT(*) AS TRANSACTION_COUNT FROM ETHEREUM.TRANSACTIONS WHERE TO_ADDRESS = '0xae7ab96520de3a18e5e111b5eaab095312d7fe84' AND FROM_ADDRESS != '0x0000000000000000000000000000000000000000' GROUP BY FROM_ADDRESS ORDER BY TRANSACTION_COUNT DESC LIMIT 400;"
            ),
            queryType: DataTypes.QueryType.SQL,
            queryParameters: queryParams,
            timeout: uint64(block.timestamp + 30 minutes),
            callbackClientContractAddress: address(this),
            callbackGasLimit: 400_000,
            callbackData: "",
            zkVerficiation: DataTypes.ZKVerification.External
        });

        _queryHash = IZKPay(_zkpay).queryWithNative{ value: msg.value }(queryData);
    }

    function sxtCallback(
        DataTypes.QueryResult calldata queryResult,
        bytes calldata callbackData,
        DataTypes.ZKVerification zkVerficiation
    ) external override onlyZKPay onlyOnce {
        require(_queryHash != 0, "Invalid query hash");
        require(queryResult.queryHash == _queryHash, "Query hash does not match");

        for (uint256 i = 0; i < queryResult.columns[0].values.length; i++) {
            address recipient = abi.decode(queryResult.columns[0].values[i], (address));
            _token.safeTransfer(recipient, AIRDROP_AMOUNT);
        }
    }

    function sxtErrorCallback(
        DataTypes.ZKpayError calldata error,
        bytes calldata callbackData
    ) external override onlyZKPay {
        emit LogError(error.code, error.message);
    }

    function withdraw() external onlyOwner {
        (bool success,) = _owner.call{ value: address(this).balance }("");
        require(success, "Failed to send Ether");
    }

    function cancelQuery(bytes32 queryHash) external onlyOwner {
        IZKPay(_zkpay).cancelQueryPayment(queryHash);
    }

    receive() external payable {
        revert Errors.NotSupportedMethod();
    }
}
