
import React from 'react';
import { ethers } from 'ethers';

const contractABI = [
  "function initialize(address zkpay) external",
  "function queryZKPay() external payable",
  "function withdraw() external",
  "function cancelQuery(bytes32 queryHash) external",
  "function _owner() public view returns (address)",
  "function _zkpay() public view returns (address)",
  "function _queryHash() public view returns (bytes32)"
];

const ContractInteraction: React.FC = () => {
  const [ownerAddress, setOwnerAddress] = React.useState<string>('');
  const [zkPayAddress, setZkPayAddress] = React.useState<string>('');
  const [queryAmount, setQueryAmount] = React.useState<string>('');
  const [queryHash, setQueryHash] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string>('');

  const contractAddress = '0xe78890E5b555e3FE258Af993A1ECd64ff523815B';
  const chainId = 17000; // Holesky testnet

  const getContract = async () => {
    if (typeof window.ethereum !== 'undefined') {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      return new ethers.Contract(contractAddress, contractABI, signer);
    }
    throw new Error('Please install MetaMask!');
  };

  const checkNetwork = async () => {
    if (typeof window.ethereum !== 'undefined') {
      const currentChainId = await window.ethereum.request({ method: 'eth_chainId' });
      if (parseInt(currentChainId, 16) !== chainId) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: `0x${chainId.toString(16)}` }],
          });
        } catch (error) {
          throw new Error('Please switch to the Holesky testnet!');
        }
      }
    }
  };

  const handleInitialize = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const tx = await contract.initialize(zkPayAddress);
      await tx.wait();
      setErrorMessage('Contract initialized successfully!');
    } catch (error) {
      setErrorMessage((error as Error).message);
    }
  };

  const handleQueryZKPay = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      
      const init = await contract._zkpay();
      console.log('Current ZKPay:', init);
      
      const owner = await contract._owner();
      console.log('Contract owner:', owner);
      
      const zkpayAddress = await contract._zkpay();
      console.log({
        zkpayAddress,
        queryAmount,
        parsedAmount: ethers.utils.parseEther(queryAmount).toString()
      });
  
      const tx = await contract.queryZKPay({ 
        value: ethers.utils.parseEther("0.01"), // Fixed small amount for testing
        gasLimit: 1000000
      });
      await tx.wait();
      const newQueryHash = await contract._queryHash();
      setQueryHash(newQueryHash);
      setErrorMessage('Query sent successfully!');
    } catch (error: any) {
      console.error('Error details:', {
        message: error.message,
        code: error.code,
        errorData: error.error?.data
      });
      setErrorMessage(error.message || 'Unknown error');
    }
  };

  const handleWithdraw = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const tx = await contract.withdraw();
      await tx.wait();
      setErrorMessage('Withdrawal successful!');
    } catch (error) {
      setErrorMessage((error as Error).message);
    }
  };

  const handleCancelQuery = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const tx = await contract.cancelQuery(queryHash);
      await tx.wait();
      setErrorMessage('Query cancelled successfully!');
    } catch (error) {
      setErrorMessage((error as Error).message);
    }
  };

  React.useEffect(() => {
    const fetchContractInfo = async () => {
      try {
        const contract = await getContract();
        const fetchedOwnerAddress = await contract._owner();
        const fetchedZkPayAddress = await contract._zkpay();
        setOwnerAddress(fetchedOwnerAddress);
        setZkPayAddress(fetchedZkPayAddress);
      } catch (error) {
        setErrorMessage((error as Error).message);
      }
    };
    fetchContractInfo();
  }, []);

  return (
    <div className="p-5">
      <h1 className="text-2xl font-bold mb-4">Contract Interaction</h1>
      
      <div className="mb-4">
        <p>Owner Address: {ownerAddress}</p>
        <p>ZKPay Address: {zkPayAddress}</p>
      </div>

      <div className="mb-4">
        <input
          type="text"
          value={zkPayAddress}
          onChange={(e) => setZkPayAddress(e.target.value)}
          placeholder="ZKPay Address"
          className="border p-2 mr-2"
        />
        <button onClick={handleInitialize} className="bg-blue-500 text-white p-2 rounded">
          Initialize Contract
        </button>
      </div>

      <div className="mb-4">
        <input
          type="text"
          value={queryAmount}
          onChange={(e) => setQueryAmount(e.target.value)}
          placeholder="Query Amount (ETH)"
          className="border p-2 mr-2"
        />
        <button onClick={handleQueryZKPay} className="bg-green-500 text-white p-2 rounded">
          Query ZKPay
        </button>
      </div>

      <div className="mb-4">
        <button onClick={handleWithdraw} className="bg-yellow-500 text-white p-2 rounded">
          Withdraw Funds
        </button>
      </div>

      <div className="mb-4">
        <input
          type="text"
          value={queryHash}
          onChange={(e) => setQueryHash(e.target.value)}
          placeholder="Query Hash"
          className="border p-2 mr-2"
        />
        <button onClick={handleCancelQuery} className="bg-red-500 text-white p-2 rounded">
          Cancel Query
        </button>
      </div>

      {errorMessage && (
        <div className="text-red-500 mt-4">
          {errorMessage}
        </div>
      )}
    </div>
  );
};

export { ContractInteraction as component };
