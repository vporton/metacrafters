import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import OurTokenModule from "./OurToken";

const CrowdFundingModule = buildModule("LockModule", (m) => {
  const { token } = m.useModule(OurTokenModule);
  
  const crowdFunding = m.contract("CrowdFunding", [token]);

  return { crowdFunding };
});

export default CrowdFundingModule;
