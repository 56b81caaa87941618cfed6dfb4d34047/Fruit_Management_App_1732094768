
import React from 'react';
import * as ethers from 'ethers';

const CONTRACT_ADDRESS = '0x501Dc59508Db1FC91872cDC357Fc34814787CaC3';
const CHAIN_ID = 17000;

const ABI = [
  "function queryZKPay() external payable",
  "function withdraw() external",
  "function cancelQuery(bytes32 queryHash) external",
  "function _airdropExecuted() public view returns (bool)",
  "function _queryHash() public view returns (bytes32)"
];

const AirdropClientInteraction: React.FC = () => {
  const [provider, setProvider] = React.useState<ethers.providers.Web3Provider | null>(null);
  const [contract, setContract] = React.useState<ethers.Contract | null>(null);
  const [airdropExecuted, setAirdropExecuted] = React.useState<boolean>(false);
  const [queryHash, setQueryHash] = React.useState<string>('');
  const [status, setStatus] = React.useState<string>('');

  React.useEffect(() => {
    const init = async () => {
      if (window.ethereum) {
        const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
        setProvider(web3Provider);
        const signer = web3Provider.getSigner();
        const contractInstance = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
        setContract(contractInstance);
        await updateContractState(contractInstance);
      }
    };
    init();
  }, []);

  const updateContractState = async (contractInstance: ethers.Contract) => {
    try {
      const executed = await contractInstance._airdropExecuted();
      setAirdropExecuted(executed);
      const hash = await contractInstance._queryHash();
      setQueryHash(hash);
    } catch (error) {
      console.error('Error updating contract state:', error);
    }
  };

  const connectWallet = async () => {
    if (!provider) return;
    try {
      await provider.send("eth_requestAccounts", []);
      const network = await provider.getNetwork();
      if (network.chainId !== CHAIN_ID) {
        await switchChain();
      }
      setStatus('Wallet connected');
    } catch (error) {
      console.error('Error connecting wallet:', error);
      setStatus('Failed to connect wallet');
    }
  };

  const switchChain = async () => {
    if (!provider) return;
    try {
      await provider.send("wallet_switchEthereumChain", [{ chainId: ethers.utils.hexValue(CHAIN_ID) }]);
    } catch (error) {
      console.error('Error switching chain:', error);
      setStatus('Failed to switch chain');
    }
  };

  const queryZKPay = async () => {
    if (!contract || !provider) {
      await connectWallet();
      return;
    }
    try {
      const tx = await contract.queryZKPay({ value: ethers.utils.parseEther("0.1") });
      await tx.wait();
      setStatus('Query sent successfully');
      await updateContractState(contract);
    } catch (error) {
      console.error('Error querying ZKPay:', error);
      setStatus('Failed to query ZKPay');
    }
  };

  const withdraw = async () => {
    if (!contract || !provider) {
      await connectWallet();
      return;
    }
    try {
      const tx = await contract.withdraw();
      await tx.wait();
      setStatus('Withdrawal successful');
    } catch (error) {
      console.error('Error withdrawing:', error);
      setStatus('Failed to withdraw');
    }
  };

  const cancelQuery = async () => {
    if (!contract || !provider) {
      await connectWallet();
      return;
    }
    try {
      const tx = await contract.cancelQuery(queryHash);
      await tx.wait();
      setStatus('Query cancelled successfully');
      await updateContractState(contract);
    } catch (error) {
      console.error('Error cancelling query:', error);
      setStatus('Failed to cancel query');
    }
  };

  return (
    <div className="p-5">
      <h1 className="text-2xl font-bold mb-4">Airdrop Client Interaction</h1>
      <div className="mb-4">
        <button onClick={connectWallet} className="bg-blue-500 text-white px-4 py-2 rounded-lg mr-2">Connect Wallet</button>
        <button onClick={queryZKPay} className="bg-green-500 text-white px-4 py-2 rounded-lg mr-2">Query ZKPay</button>
        <button onClick={withdraw} className="bg-yellow-500 text-white px-4 py-2 rounded-lg mr-2">Withdraw</button>
        <button onClick={cancelQuery} className="bg-red-500 text-white px-4 py-2 rounded-lg">Cancel Query</button>
      </div>
      <div className="mb-4">
        <p>Airdrop Executed: {airdropExecuted ? 'Yes' : 'No'}</p>
        <p>Query Hash: {queryHash}</p>
      </div>
      <div className="text-sm text-gray-600">
        <p>Status: {status}</p>
      </div>
    </div>
  );
};

export { AirdropClientInteraction as component };
