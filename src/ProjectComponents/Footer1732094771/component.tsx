import React from 'react';
import { ethers } from 'ethers';

const contractABI = [
  "function initialize(address zkpay) external",
  "function queryZKPay() external payable",
  "function withdraw() external",
  "function cancelQuery(bytes32 queryHash) external",
  "function _owner() public view returns (address)",
  "function _zkpay() public view returns (address)",
  "function _queryHash() public view returns (bytes32)",
  "function addTrustedRelayer(address relayer) external",
  "function getAcceptedAssetMethod(address) external view returns (tuple(bool,bool))",
  "function isTrustedRelayer(address) external view returns (bool)",
  "function setAcceptedAsset(address,bool,bool) external"
];

const ContractInteraction: React.FC = () => {
  const [ownerAddress, setOwnerAddress] = React.useState<string>('');
  const [zkPayAddress, setZkPayAddress] = React.useState<string>('');
  const [queryAmount, setQueryAmount] = React.useState<string>('');
  const [queryHash, setQueryHash] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string>('');

  const contractAddress = '0xe78890E5b555e3FE258Af993A1ECd64ff523815B';
  const chainId = 17000;

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
    } catch (error: any) {
      console.error('Initialize error:', error);
      setErrorMessage(error.message);
    }
  };

  const setupRelayer = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
       
      const owner = await contract._owner();
      const caller = await signer.getAddress();
      console.log('Access check:', {
       owner,
       caller, 
       isOwner: owner.toLowerCase() === caller.toLowerCase()
     });
  
     if (owner.toLowerCase() !== caller.toLowerCase()) {
       throw new Error('Must be owner to add trusted relayer');
     }
  
     // First set accepted asset
     console.log('Setting accepted asset...');
     const setAssetTx = await contract.setAcceptedAsset(
       ethers.constants.AddressZero,
       true,
       true, 
       {
         gasLimit: 1000000
       }
     );
     await setAssetTx.wait();
     console.log('Asset acceptance set');
  
     // Then add trusted relayer
     console.log('Adding trusted relayer...');
     const tx = await contract.addTrustedRelayer(caller, {
       gasLimit: 1000000
     });
     await tx.wait();
     console.log('Relayer added');
  
   } catch (error: any) {
     console.error('Setup error:', {
       code: error?.code,
       message: error?.message,
       data: error?.error?.data,
       reason: error?.error?.reason,
       stack: error?.stack
     });
   }
  };

  const handleQueryZKPay = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      
      const acceptedAsset = await contract.getAcceptedAssetMethod(ethers.constants.AddressZero);
      console.log('Native token accepted?', acceptedAsset);
      
      const owner = await contract._owner();
      const trustedRelayer = await contract.isTrustedRelayer(owner);
      console.log('Is trusted relayer?', trustedRelayer);
      
      const tx = await contract.queryZKPay({ 
        value: ethers.utils.parseEther("0.1"),
        gasLimit: 1000000
      });
      await tx.wait();
      
      const newQueryHash = await contract._queryHash();
      setQueryHash(newQueryHash);
      setErrorMessage('Query sent successfully!');
    } catch (error: any) {
      console.error('Query error:', {
        code: error?.code,
        message: error?.message,
        data: error?.error?.data,
        reason: error?.error?.reason
      });
      setErrorMessage(error.message);
    }
  };

  const handleWithdraw = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const tx = await contract.withdraw();
      await tx.wait();
      setErrorMessage('Withdrawal successful!');
    } catch (error: any) {
      console.error('Withdraw error:', error);
      setErrorMessage(error.message);
    }
  };

  const handleCancelQuery = async () => {
    try {
      await checkNetwork();
      const contract = await getContract();
      const tx = await contract.cancelQuery(queryHash);
      await tx.wait();
      setErrorMessage('Query cancelled successfully!');
    } catch (error: any) {
      console.error('Cancel error:', error);
      setErrorMessage(error.message);
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
      } catch (error: any) {
        console.error('Fetch error:', error);
        setErrorMessage(error.message);
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
        <button onClick={setupRelayer} className="bg-purple-500 text-white p-2 rounded">
          Setup Relayer
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
