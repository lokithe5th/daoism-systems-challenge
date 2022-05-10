import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React from "react";
import { Link } from "react-router-dom";
import { Address, Balance, EtherInput, AddressInput } from "../components";
import { Button, Col, Menu, Row } from "antd";

/**
 * web3 props can be passed from '../App.jsx' into your local view component for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded using ethers contract module. More here https://docs.ethers.io/v5/api/contract/contract/
 * @returns react component
 **/
function Home({ yourLocalBalance, readContracts, writeContracts, tx }) {
  // you can also use hooks locally in your component of choice
  // in this case, let's keep track of 'purpose' variable from our contract
  const owners = useContractReader(readContracts, "GnosisSafe", "getOwners()");


  return (
    <div>
      <div style={{ margin: 32 }}>
        Add New Signer Here
      </div>
      <div style={{ margin: 32 }}>
      <AddressInput></AddressInput>
      <Button type={"primary"} onClick={()=>{
                  tx( writeContracts.Voting.submitProposal({ value: 0}()))
                }}>Propose Signer</Button>
      </div>
      <div style={{ margin: 32 }}>
      </div>
        

      <div style={{ margin: 32 }}>
      </div>
      <div style={{ margin: 32 }}>
        <span style={{ marginRight: 8 }}>🛠</span>
        Tinker with your smart contract using the <Link to="/debug">"Debug Contract"</Link> tab.
      </div>
    </div>
  );
}

export default Home;
