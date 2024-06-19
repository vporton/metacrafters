import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import OurTokenModule from "./OurToken";

const CrowdFundingModule = buildModule("CrowdFundingModule", (m) => {
  const { token } = m.useModule(OurTokenModule);
  const crowdFunding = m.contract("CrowdFunding");
  m.call(crowdFunding, "init", [token]);

  return { crowdFunding };
});

export default CrowdFundingModule;
