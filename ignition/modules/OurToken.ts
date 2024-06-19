import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const NAME = "Our Token";
const SYMBOL = "TOK";
const SUPPLY: bigint = 100n * 10n**18n;

const OurTokenModule = buildModule("OurTokenModule", (m) => {
  const name = m.getParameter("name", NAME);
  const symbol = m.getParameter("symbol", SYMBOL);
  const supply = m.getParameter("supply", SUPPLY);

  const token = m.contract("OurToken", [name, symbol, supply]);

  return { token };
});

export default OurTokenModule;
