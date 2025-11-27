import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const proxyModule = buildModule("proxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  // 定义构造函数参数（可以从外部传入或硬编码）
  const FEE = m.getParameter("fee", "500");
  const linkAddr = m.getParameter("linkAddr", "0x...");
  const ethUsdFeed = m.getParameter("ethUsdFeed", "0x...");
  const linkUsdFeed = m.getParameter("linkUsdFeed", "0x...");

  // 部署逻辑合约（带构造函数参数）
  const auction = m.contract("NftAuction", [
    FEE,
    linkAddr,
    ethUsdFeed,
    linkUsdFeed
  ]);

  const proxy = m.contract("TransparentUpgradeableProxy", [
    auction,
    proxyAdminOwner,
    "0x", // 空的初始化数据
  ]);

  const proxyAdminAddress = m.readEventArgument(
    proxy,
    "AdminChanged",
    "newAdmin",
  );

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy, auction };
});

const auctionModule = buildModule("auctionModule", (m) => {
  const { proxy } = m.useModule(proxyModule);

  // 创建与代理交互的合约实例
  const auction = m.contractAt("NftAuction", proxy);

  return { auction, proxy };
});

export default auctionModule;