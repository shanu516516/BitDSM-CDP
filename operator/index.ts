// Description: This script demonstrates how an operator can register with the AVS and respond to tasks.
// It also demonstrates how to monitor for new tasks.
// run this using ts-node operator/index.ts

import { ethers } from "ethers";
//const { ethers } = require("ethers");
import * as dotenv from "dotenv";
//const dotenv = require("dotenv");
const fs = require('fs');
const path = require('path');
dotenv.config();

// Check if the process.env object is empty
if (!Object.keys(process.env).length) {
    throw new Error("process.env object is empty");
}

// Setup env variables
// Use RPC_URL for connecting to Holesky testnet
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
const uri = process.env.Operator_URI;
let chainId = 17000;

// Load deployment data
const coreDeploymentData = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, `../script/eigenlayer_addresses.json`),
    "utf8"
  )
);
const avsDeploymentData = JSON.parse(fs.readFileSync(path.resolve(__dirname, `../script/bitdsm_addresses.json`), 'utf8'));


const delegationManagerAddress = coreDeploymentData.holesky.delegationManager; 
const avsDirectoryAddress = coreDeploymentData.holesky.avsDirectory;

const bitDSMServiceManagerAddress = avsDeploymentData.BitDSMServiceManagerProxy;
const ecdsaStakeRegistryAddress = avsDeploymentData.ECDSAStakeRegistryProxy;



// Load ABIs
const delegationManagerABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/IDelegationManager.json'), 'utf8'));
const ecdsaRegistryABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/ECDSAStakeRegistry.json'), 'utf8'));
const bitDSMServiceManagerABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/BitDSMServiceManager.json'), 'utf8'));
const avsDirectoryABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/IAVSDirectory.json'), 'utf8'));

// Initialize contract objects from ABIs
const delegationManager = new ethers.Contract(delegationManagerAddress, delegationManagerABI, wallet);
const bitDSMServiceManager = new ethers.Contract(bitDSMServiceManagerAddress, bitDSMServiceManagerABI, wallet);
const ecdsaRegistryContract = new ethers.Contract(ecdsaStakeRegistryAddress, ecdsaRegistryABI, wallet);
const avsDirectory = new ethers.Contract(avsDirectoryAddress, avsDirectoryABI, wallet);


const signAndRespondToTask = async (taskIndex: number, taskCreatedBlock: number, taskName: string) => {
    const message = `Hello, ${taskName}`;
    const messageHash = ethers.solidityPackedKeccak256(["string"], [message]);
    const messageBytes = ethers.getBytes(messageHash);
    const signature = await wallet.signMessage(messageBytes);

    console.log(`Signing and responding to task ${taskIndex}`);

    const operators = [await wallet.getAddress()];
    const signatures = [signature];
    const signedTask = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address[]", "bytes[]", "uint32"],
        [operators, signatures, ethers.toBigInt(await provider.getBlockNumber())]
    );

    const tx = await bitDSMServiceManager.confirmDeposit(
      { name: taskName, taskCreatedBlock: taskCreatedBlock },
      taskIndex,
      signedTask
    );
    await tx.wait();
    console.log(`Responded to task.`);
};

const registerOperator = async () => {
    // Registers as an Operator in EigenLayer.
    const registered_operator = await delegationManager.isOperator(wallet.address);
    if (registered_operator) {
      console.log("Operator already registered to Core EigenLayer contracts");
    }
    else {
        console.log("Registering Operator to EigenLayer contracts");
        try {
            const tx1 = await delegationManager.registerAsOperator({
                __deprecated_earningsReceiver: await wallet.address,
                delegationApprover: "0x0000000000000000000000000000000000000000",
                stakerOptOutWindowBlocks: 0
            }, uri);
            await tx1.wait();
            console.log("Operator registered to Core EigenLayer contracts");
        } catch (error) {
            console.error("Error in registering as operator:", error);
            // terminate execution
            process.exit(1);
        }
    }
    // check if operator is already registered to AVS
    const registered_operator_avs =
      await ecdsaRegistryContract.operatorRegistered(wallet.address);
    if (registered_operator_avs) {
        console.log("Operator already registered to AVS");
        return;
    }
    else {
        const salt = ethers.hexlify(ethers.randomBytes(32));
        const expiry = Math.floor(Date.now() / 1000) + 3600; // Example expiry, 1 hour from now

        // prepare to register operator to AVS
        let operatorSignatureWithSaltAndExpiry = {
            signature: "",
            salt: salt,
            expiry: expiry
        };

        // Calculate the digest hash, which is a unique value representing the operator, avs, unique value (salt) and expiration date.
        const operatorDigestHash = await avsDirectory.calculateOperatorAVSRegistrationDigestHash(
            wallet.address,
            await bitDSMServiceManager.getAddress(),
            salt,
            expiry
        );
    
        // Sign the digest hash with the operator's private key
        console.log("Signing digest hash with operator's private key");
        const operatorSigningKey = new ethers.SigningKey(process.env.PRIVATE_KEY!);
        const operatorSignedDigestHash = operatorSigningKey.sign(operatorDigestHash);

        // Encode the signature in the required format
        operatorSignatureWithSaltAndExpiry.signature = ethers.Signature.from(operatorSignedDigestHash).serialized;

        console.log("Registering Operator to AVS Registry contract");
    
        // Register Operator to AVS
        // Per release here: https://github.com/Layr-Labs/eigenlayer-middleware/blob/v0.2.1-mainnet-rewards/src/unaudited/ECDSAStakeRegistry.sol#L49
        const tx2 = await ecdsaRegistryContract.registerOperatorWithSignature(
            operatorSignatureWithSaltAndExpiry,
            wallet.address
        );
        await tx2.wait();
        console.log("Operator registered on AVS successfully");
    }
};

const monitorNewTasks = async () => {
    console.log(`Creating new task "EigenWorld"`);
    await bitDSMServiceManager.createNewTask("EigenWorld");

    bitDSMServiceManager.on("NewTaskCreated", async (taskIndex: number, task: any) => {
        console.log(`New task detected: Hello, ${task.name}`);
        await signAndRespondToTask(taskIndex, task.taskCreatedBlock, task.name);
    });

    console.log("Monitoring for new tasks...");
};

const main = async () => {
    await registerOperator();
   monitorNewTasks().catch((error) => {
       console.error("Error monitoring tasks:", error);
   });
};

main().catch((error) => {
    console.error("Error in main function:", error);
});