/* 世界地图 Wiki 入口：静态页面只保留 div 挂载点，交互控件由脚本建立。 */
(function () {
  "use strict";
  if (window.NrcWorldMap) return;
  const payloads = new Map();
  const loads = new Map();
  const decoded = new Map();
  const config = {"assets":{"/map-media/tiles-08e9506c2555bae050be/01.png":"Map_Mainland_Surface_Tile01.png","/map-media/tiles-08e9506c2555bae050be/02.png":"Map_Mainland_Surface_Tile02.png","/map-media/tiles-08e9506c2555bae050be/03.png":"Map_Mainland_Surface_Tile03.png","/map-media/tiles-08e9506c2555bae050be/04.png":"Map_Mainland_Surface_Tile04.png","/map-media/tiles-08e9506c2555bae050be/05.png":"Map_Mainland_Surface_Tile05.png","/map-media/tiles-08e9506c2555bae050be/06.png":"Map_Mainland_Surface_Tile06.png","/map-media/tiles-08e9506c2555bae050be/07.png":"Map_Mainland_Surface_Tile07.png","/map-media/tiles-08e9506c2555bae050be/08.png":"Map_Mainland_Surface_Tile08.png","/map-media/tiles-08e9506c2555bae050be/09.png":"Map_Mainland_Surface_Tile09.png","/map-media/tiles-08e9506c2555bae050be/10.png":"Map_Mainland_Surface_Tile10.png","/map-media/tiles-08e9506c2555bae050be/11.png":"Map_Mainland_Surface_Tile11.png","/map-media/tiles-08e9506c2555bae050be/12.png":"Map_Mainland_Surface_Tile12.png","/map-media/tiles-08e9506c2555bae050be/13.png":"Map_Mainland_Surface_Tile13.png","/map-media/tiles-08e9506c2555bae050be/14.png":"Map_Mainland_Surface_Tile14.png","/map-media/tiles-08e9506c2555bae050be/15.png":"Map_Mainland_Surface_Tile15.png","/map-media/tiles-08e9506c2555bae050be/16.png":"Map_Mainland_Surface_Tile16.png","/map-media/tiles-125d870bfcf691a2599f/01.png":"Map_Mainland_Unexplored_Tile01.png","/map-media/tiles-125d870bfcf691a2599f/02.png":"Map_Mainland_Unexplored_Tile02.png","/map-media/tiles-125d870bfcf691a2599f/03.png":"Map_Mainland_Unexplored_Tile03.png","/map-media/tiles-125d870bfcf691a2599f/04.png":"Map_Mainland_Unexplored_Tile04.png","/map-media/tiles-125d870bfcf691a2599f/05.png":"Map_Mainland_Unexplored_Tile05.png","/map-media/tiles-125d870bfcf691a2599f/06.png":"Map_Mainland_Unexplored_Tile06.png","/map-media/tiles-125d870bfcf691a2599f/07.png":"Map_Mainland_Unexplored_Tile07.png","/map-media/tiles-125d870bfcf691a2599f/08.png":"Map_Mainland_Unexplored_Tile08.png","/map-media/tiles-125d870bfcf691a2599f/09.png":"Map_Mainland_Unexplored_Tile09.png","/map-media/tiles-125d870bfcf691a2599f/10.png":"Map_Mainland_Unexplored_Tile10.png","/map-media/tiles-125d870bfcf691a2599f/11.png":"Map_Mainland_Unexplored_Tile11.png","/map-media/tiles-125d870bfcf691a2599f/12.png":"Map_Mainland_Unexplored_Tile12.png","/map-media/tiles-125d870bfcf691a2599f/13.png":"Map_Mainland_Unexplored_Tile13.png","/map-media/tiles-125d870bfcf691a2599f/14.png":"Map_Mainland_Unexplored_Tile14.png","/map-media/tiles-125d870bfcf691a2599f/15.png":"Map_Mainland_Unexplored_Tile15.png","/map-media/tiles-125d870bfcf691a2599f/16.png":"Map_Mainland_Unexplored_Tile16.png","/map-media/tiles-880f4ac73b07e89f13d4/01.png":"Map_Mainland_Underground_Tile01.png","/map-media/tiles-880f4ac73b07e89f13d4/02.png":"Map_Mainland_Underground_Tile02.png","/map-media/tiles-880f4ac73b07e89f13d4/03.png":"Map_Mainland_Underground_Tile03.png","/map-media/tiles-880f4ac73b07e89f13d4/04.png":"Map_Mainland_Underground_Tile04.png","/map-media/tiles-880f4ac73b07e89f13d4/05.png":"Map_Mainland_Underground_Tile05.png","/map-media/tiles-880f4ac73b07e89f13d4/06.png":"Map_Mainland_Underground_Tile06.png","/map-media/tiles-880f4ac73b07e89f13d4/07.png":"Map_Mainland_Underground_Tile07.png","/map-media/tiles-880f4ac73b07e89f13d4/08.png":"Map_Mainland_Underground_Tile08.png","/map-media/tiles-880f4ac73b07e89f13d4/09.png":"Map_Mainland_Underground_Tile09.png","/map-media/tiles-880f4ac73b07e89f13d4/10.png":"Map_Mainland_Underground_Tile10.png","/map-media/tiles-880f4ac73b07e89f13d4/11.png":"Map_Mainland_Underground_Tile11.png","/map-media/tiles-880f4ac73b07e89f13d4/12.png":"Map_Mainland_Underground_Tile12.png","/map-media/tiles-880f4ac73b07e89f13d4/13.png":"Map_Mainland_Underground_Tile13.png","/map-media/tiles-880f4ac73b07e89f13d4/14.png":"Map_Mainland_Underground_Tile14.png","/map-media/tiles-880f4ac73b07e89f13d4/15.png":"Map_Mainland_Underground_Tile15.png","/map-media/tiles-880f4ac73b07e89f13d4/16.png":"Map_Mainland_Underground_Tile16.png","/map-media/tiles-54c7170546b6109bab59/01.png":"Map_Mainland_Surface_Tile01_HD.png","/map-media/tiles-54c7170546b6109bab59/02.png":"Map_Mainland_Surface_Tile02_HD.png","/map-media/tiles-54c7170546b6109bab59/03.png":"Map_Mainland_Surface_Tile03_HD.png","/map-media/tiles-54c7170546b6109bab59/04.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-54c7170546b6109bab59/05.png":"Map_Mainland_Surface_Tile05_HD.png","/map-media/tiles-54c7170546b6109bab59/06.png":"Map_Mainland_Surface_Tile06_HD.png","/map-media/tiles-54c7170546b6109bab59/07.png":"Map_Mainland_Surface_Tile07_HD.png","/map-media/tiles-54c7170546b6109bab59/08.png":"Map_Mainland_Surface_Tile08_HD.png","/map-media/tiles-54c7170546b6109bab59/09.png":"Map_Mainland_Surface_Tile09_HD.png","/map-media/tiles-54c7170546b6109bab59/10.png":"Map_Mainland_Surface_Tile10_HD.png","/map-media/tiles-54c7170546b6109bab59/11.png":"Map_Mainland_Surface_Tile11_HD.png","/map-media/tiles-54c7170546b6109bab59/12.png":"Map_Mainland_Surface_Tile12_HD.png","/map-media/tiles-54c7170546b6109bab59/13.png":"Map_Mainland_Surface_Tile13_HD.png","/map-media/tiles-54c7170546b6109bab59/14.png":"Map_Mainland_Surface_Tile14_HD.png","/map-media/tiles-54c7170546b6109bab59/15.png":"Map_Mainland_Surface_Tile15_HD.png","/map-media/tiles-54c7170546b6109bab59/16.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-216fd6ee47baf1806cea/01.png":"Map_Mainland_Unexplored_Tile01_HD.png","/map-media/tiles-216fd6ee47baf1806cea/02.png":"Map_Mainland_Unexplored_Tile02_HD.png","/map-media/tiles-216fd6ee47baf1806cea/03.png":"Map_Mainland_Unexplored_Tile03_HD.png","/map-media/tiles-216fd6ee47baf1806cea/04.png":"Map_Mainland_Unexplored_Tile04_HD.png","/map-media/tiles-216fd6ee47baf1806cea/05.png":"Map_Mainland_Unexplored_Tile05_HD.png","/map-media/tiles-216fd6ee47baf1806cea/06.png":"Map_Mainland_Unexplored_Tile06_HD.png","/map-media/tiles-216fd6ee47baf1806cea/07.png":"Map_Mainland_Unexplored_Tile07_HD.png","/map-media/tiles-216fd6ee47baf1806cea/08.png":"Map_Mainland_Unexplored_Tile08_HD.png","/map-media/tiles-216fd6ee47baf1806cea/09.png":"Map_Mainland_Unexplored_Tile09_HD.png","/map-media/tiles-216fd6ee47baf1806cea/10.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-216fd6ee47baf1806cea/11.png":"Map_Mainland_Unexplored_Tile11_HD.png","/map-media/tiles-216fd6ee47baf1806cea/12.png":"Map_Mainland_Unexplored_Tile12_HD.png","/map-media/tiles-216fd6ee47baf1806cea/13.png":"Map_Mainland_Unexplored_Tile13_HD.png","/map-media/tiles-216fd6ee47baf1806cea/14.png":"Map_Mainland_Unexplored_Tile14_HD.png","/map-media/tiles-216fd6ee47baf1806cea/15.png":"Map_Mainland_Unexplored_Tile15_HD.png","/map-media/tiles-216fd6ee47baf1806cea/16.png":"Map_Mainland_Unexplored_Tile16_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/01.png":"Map_Mainland_Underground_Tile01_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/02.png":"Map_Mainland_Underground_Tile02_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/03.png":"Map_Mainland_Underground_Tile03_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/04.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/05.png":"Map_Mainland_Underground_Tile05_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/06.png":"Map_Mainland_Underground_Tile06_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/07.png":"Map_Mainland_Underground_Tile07_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/08.png":"Map_Mainland_Underground_Tile08_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/09.png":"Map_Mainland_Underground_Tile09_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/10.png":"Map_Mainland_Underground_Tile10_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/11.png":"Map_Mainland_Underground_Tile11_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/12.png":"Map_Mainland_Underground_Tile12_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/13.png":"Map_Mainland_Underground_Tile13_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/14.png":"Map_Mainland_Underground_Tile14_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/15.png":"Map_Mainland_Underground_Tile15_HD.png","/map-media/tiles-3d1d6db87c3aaf0d5759/16.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/d6251717316c302f1bb9.png":"MapIcon_SanctuaryLarge_Default.png","/map-media/6e571d9c3e9058cd27c7.png":"MapIcon_Home.png","/map-media/e461ee767c57c6b16d09.png":"MapIcon_SanctuarySmall_Default.png","/map-media/87b475962539a30dea83.png":"MapIcon_Alchemy.png","/map-media/34d75171913304c688eb.png":"MapIcon_DungeonEntrance.png","/map-media/ae361a469a4a117c2b86.png":"MapIcon_Teleport.png","/map-media/bb619d9f0be2f4743945.png":"PetAvatar_3397.png","/map-media/a51b86df616fc1b7bb1f.png":"MapMarkerPortrait_4078_1.png","/map-media/a010300fb5a448158629.png":"MapIcon_ForceTester.png","/map-media/5e1d3eb561e2f95bd31c.png":"MapIcon_OwlStatue.png","/map-media/fb6d6d78981819bf4993.png":"MapIcon_WeatherStatue.png","/map-media/fc808b881d102c10303b.png":"MapIcon_NightmareAltar.png","/map-media/89d454f2e89b72c7d984.png":"MapIcon_MiniChallenge.png","/map-media/a13993742bb48ab5a7e5.png":"MapIcon_CapsuleMachine.png","/map-media/cb4e18e65b23dff850d0.png":"MapIcon_StarlightDuel.png","/map-media/956b1dfc6937864919bb.png":"MapIcon_Brazier.png","/map-media/fb5f2119919e9ce9b977.png":"MapIcon_CrystalTree.png","/map-media/020f9c0982a8f323e5d0.png":"PetAvatar_3347.png","/map-media/e206663f62378bf2d7cd.png":"MapIcon_SeasonMoon.png","/map-media/4f5f6a765d22b4364744.png":"MapIcon_ClockPart.png","/map-media/35379b75e60c251e95c3.png":"MapIcon_ChestBasic.png","/map-media/a7c832487391b880957a.png":"MapIcon_ChestAdvanced.png","/map-media/a0115461fa3a9b42119a.png":"MapIcon_ChestIntermediate.png","/map-media/74de5ae54813d3d72912.png":"MapIcon_SparkleBasic.png","/map-media/4e24bdbd7c5d3dca7cec.png":"MapIcon_SparkleAdvanced.png","/map-media/bd4047089a5af6c37712.png":"MapIcon_WisdomTreeBlue.png","/map-media/994311198a5f1e11b036.png":"MapIcon_WisdomTreeGold.png","/map-media/e432cde25b7c1b1aebdc.png":"MapIcon_WisdomTreePurple.png","/map-media/6d0974e0b107bbfe4761.png":"MapIcon_OwlStarBlue.png","/map-media/68e4686a82ce01bc70f4.png":"MapIcon_OwlStarGold.png","/map-media/ff71826874fe945291d1.png":"MapIcon_OwlStarPurple.png","/map-media/4bde46dd7a8ba72691df.png":"MapIcon_Music.png","/map-media/577b84f7a1de3dc36314.png":"MapIcon_MagicStone.png","/map-media/e508fb2d80879bf65c94.png":"MapIcon_Shop.png","/map-media/b7ca4889fa69bfa5870d.png":"MapIcon_FashionShop.png","/map-media/f2ca521ae57bb40dae94.svg":"MapIcon_Habitat.svg","/map-media/6227421a7f5034f20278.png":"MapGathering_100622.png","/map-media/87d6f6f2d1e0483ebc90.png":"MapGathering_100625.png","/map-media/fe1d704c811947c5c309.png":"MapIcon_CocoaFruit.png","/map-media/262ee968fb5405a812bb.png":"MapGathering_100604.png","/map-media/02c18e63c167e8051922.png":"MapGathering_100605.png","/map-media/a0c11514a71c96c17980.png":"MapGathering_100624.png","/map-media/0866579a5f81c0678730.png":"MapGathering_100684.png","/map-media/2cabdcf1ab6273d9d069.png":"MapGathering_100608.png","/map-media/c2c347798165f5e73fe3.png":"MapGathering_100627.png","/map-media/457ba5a911f9bf5f70d7.png":"MapGathering_100763.png","/map-media/7e316fa6db6c383fa969.png":"MapGathering_100751.png","/map-media/b14b4ac05dedac6f980a.png":"MapGathering_100686.png","/map-media/4e52bb45e28d8fbcded8.png":"MapIcon_Fig.png","/map-media/e2800f8b05e25df58438.png":"MapGathering_100692.png","/map-media/c0ef5a4e0b64b137fd23.png":"MapGathering_100867.png","/map-media/7a834e21d939e738e859.png":"MapGathering_100868.png","/map-media/7f759ae9db3cfd0f8695.png":"MapGathering_100691.png","/map-media/4b20d27c33c24e6de344.png":"MapGathering_100687.png","/map-media/1e8bbea516f2793dfe97.png":"MapGathering_100754.png","/map-media/a075675d3cb72a27f982.png":"MapGathering_100755.png","/map-media/02584c5977c2568344b5.png":"MapIcon_FlameStone.png","/map-media/843b697b704e71666429.png":"MapGathering_100690.png","/map-media/9c4a7122c13f6b5360e8.png":"MapGathering_100607.png","/map-media/3e6a779c1c1c751dbbe1.png":"MapGathering_100869.png","/map-media/e554cafb2d9fccdceede.png":"MapGathering_100621.png","/map-media/38dc1bf3515cb3641fbb.png":"MapGathering_100706.png","/map-media/5b7cd42c98e950b2c17d.png":"MapIcon_PurpleVelvetFlower.png","/map-media/9ff1747d0f7f1e19fc74.png":"MapGathering_100682.png","/map-media/0ad5827aed44d99b4396.png":"MapGathering_100764.png","/map-media/d5cd39d298467bca6310.png":"MapIcon_CrystalFlower.png","/map-media/929f87eacc9786b9049b.png":"MapIcon_WishCrystal.png","/map-media/8257f45366fee7b801d4.png":"MapGathering_100689.png","/map-media/f2e915acf80b6006526d.png":"MapGathering_100694.png","/map-media/e4a15cfd66b6c8349f57.png":"MapGathering_100606.png","/map-media/7b10697bc607a3c9ef7a.png":"MapGathering_100681.png","/map-media/7229c52ca0c5e3e5417a.png":"MapGathering_100750.png","/map-media/b183c5e4286301eec410.png":"MapGathering_100623.png","/map-media/4433b8e9cb6ecbcf3050.png":"MapIcon_ButterflyOrchid.png","/map-media/4d1164c25a1ac39fa09e.png":"MapGathering_100762.png","/map-media/d7866347e75e4c23f5ba.png":"MapGathering_100693.png","/map-media/56170a9e170d7dbfb961.png":"MapGathering_100753.png","/map-media/fecc33f5f915e3fa5532.png":"MapGathering_100695.png","/map-media/84c111cf602b283a5b5e.png":"MapIcon_MagicFruit.png","/map-media/23e80176b47dfdb87a7d.png":"MapIcon_MagicMushroom.png","/map-media/39916cf4951cff963934.png":"MapGathering_100683.png","/map-media/958d1c44d65ad163ebe8.png":"MapGathering_100628.png","/map-media/a6139a6a8bc983a4b624.png":"MapIcon_BattleTower.png","/map-media/ceca68c2914b26d11f54.png":"MapIcon_SeasonResearcher.png","/map-media/68a05d99324fa97b8819.png":"MapIcon_Trial.png","/map-media/6fd8826f5070303e8c00.png":"MapIcon_BlackCladOpponent.png","/map-media/5cc81e3af1989c6b8719.png":"Map_Mainland_Interior_Layer02.png","/map-media/0d454f1dea35d5fc6d6a.png":"Map_Mainland_Interior_Layer02_HD.png","/map-media/9e5fd310d044ccf090fc.png":"Map_Mainland_Interior_Layer04.png","/map-media/475497b3a19e1efedccf.png":"Map_Mainland_Interior_Layer04_HD.png","/map-media/e0f549e1ff4615d79905.png":"Map_Mainland_Interior_Layer05.png","/map-media/4785ec0881c67c229e7e.png":"Map_Mainland_Interior_Layer05_HD.png","/map-media/13a82b4f4a728505491c.png":"Map_Mainland_Interior_Layer07.png","/map-media/3a8d8c3b1571bad748b1.png":"Map_Mainland_Interior_Layer07_HD.png","/map-media/6b483e91d2f3f9367639.png":"Map_Mainland_Interior_Layer08.png","/map-media/29e58d2e8d144e67f378.png":"Map_Mainland_Interior_Layer08_HD.png","/map-media/fd159d5628fb2bf445bc.png":"Map_Mainland_Interior_Layer10.png","/map-media/410972cf90a86fb4e386.png":"Map_Mainland_Interior_Layer10_HD.png","/map-media/ae933f25cf55b76a3a81.png":"Map_Mainland_Interior_Layer12.png","/map-media/f3775aa15f2f2afeb0b0.png":"Map_Mainland_Interior_Layer12_HD.png","/map-media/c00d466d3bd6d8b52b39.png":"Map_Mainland_Interior_Layer17.png","/map-media/7038596875fe4ec40b9f.png":"Map_Mainland_Interior_Layer17_HD.png","/map-media/789e1eca1131a7cf66f7.png":"Map_Mainland_Interior_Layer18.png","/map-media/aff6d754c9be0df2d008.png":"Map_Mainland_Interior_Layer18_HD.png","/map-media/7f518e38ef7ad6b2ff66.png":"Map_Mainland_Interior_Layer19.png","/map-media/18ff24ee0faa1ff71287.png":"Map_Mainland_Interior_Layer19_HD.png","/map-media/bd06d074b4906c7e7e75.png":"Map_Mainland_Interior_Layer21.png","/map-media/9855d1339ae4916177fe.png":"Map_Mainland_Interior_Layer21_HD.png","/map-media/af2a295ddb0a1123d7fd.png":"Map_Mainland_Interior_Layer22.png","/map-media/df51b9c1b60a06e73566.png":"Map_Mainland_Interior_Layer22_HD.png","/map-media/1fd63bbbec401eb31af8.png":"Map_Mainland_Interior_Layer24.png","/map-media/4c560f5fefd2261b37ac.png":"Map_Mainland_Interior_Layer24_HD.png","/map-media/f4cfce7afe3a51a081bf.png":"Map_Mainland_Interior_Layer26.png","/map-media/d4af20b97bdcc8087a88.png":"Map_Mainland_Interior_Layer26_HD.png","/map-media/6de50b6350b69026e3fc.png":"Item_100699.png","/map-media/90d22fd2347ac4706248.png":"Item_100211.png","/map-media/6eb470382e8715283217.png":"Item_100212_Map.png","/map-media/10785cb7a62194ff5973.png":"Item_100201.png","/map-media/5c3edc2c2f72a33ed125.png":"Item_70_Map.png","/map-media/f0c301c1a8be03460a97.png":"Item_100003.png","/map-media/ff1db249b04d9f27067d.png":"Item_100213_Map.png","/map-media/fce3563bfddf338c198b.png":"Item_100204_Map.png","/map-media/3a7a3056a1249bc4a6ec.png":"PetAvatar_3530_Map.png","/map-media/ef6a75aa722c2ad970e2.png":"PetAvatar_3049.png","/map-media/986e87ffa6d29f181133.png":"PetAvatar_3430.png","/map-media/029e48f4219c6361c633.png":"PetAvatar_3077_Map.png","/map-media/9ebcade4438165f80973.png":"PetAvatar_3141.png","/map-media/58391225c82b860fd3ca.png":"Item_71_Map.png","/map-media/9d91c2fab1411bec15d3.png":"PetAvatar_3373_Map.png","/map-media/9e3f371aac267cc01546.png":"PetAvatar_3064.png","/map-media/7648e62c286aa7c3b219.png":"PetAvatar_3013.png","/map-media/972c94beae5ee786f61c.png":"PetAvatar_3016.png","/map-media/c932702dd2c0358e493c.png":"PetAvatar_5053_Map.png","/map-media/992397f6be451f4038a7.png":"PetAvatar_3142.png","/map-media/507add93a01c34211dba.png":"PetAvatar_3541_Map.png","/map-media/63da6d3b06d4225d47b5.png":"PetAvatar_3405.png","/map-media/215e38475bea4e8aa819.png":"PetAvatar_3124.png","/map-media/c42b454b678311dad906.png":"PetAvatar_3256_Map.png","/map-media/4eb294b24c534279c1d6.png":"PetAvatar_3507_Map.png","/map-media/7f9b716d93196fb6431b.png":"PetAvatar_3057.png","/map-media/e5ab2b10a67b97855dc3.png":"PetAvatar_3359.png","/map-media/35bb6cce8f267baf9a54.png":"PetAvatar_3197.png","/map-media/51b9f7b25801dba6471b.png":"Item_100304.png","/map-media/859f5e1f35ffd146b84d.png":"Item_100305.png","/map-media/31138ddf1e031b9d5f2e.png":"Item_100001.png","/map-media/1367f2b51920439bc92f.png":"Item_100302.png","/map-media/c948e3c8f5f4a6379491.png":"Item_100303.png","/map-media/835dbac3e010a878e49a.png":"Item_100316.png","/map-media/e19f67870a3791656e56.png":"Item_100314_Map.png","/map-media/e999929a53ed9e309cf5.png":"Item_100310_Map.png","/map-media/bff232772f94d2a6df6d.png":"Item_100307.png","/map-media/3cc20e052c82fe2958c7.png":"Item_100309_Map.png","/map-media/0b5bf5233d131ad70db4.png":"Item_100311_Map.png","/map-media/574e8cc7bf2002683732.png":"Item_100312_Map.png","/map-media/c22439525ab88255b3e3.png":"Item_100313.png","/map-media/a335b206bf0feb644628.png":"Item_100315_Map.png","/map-media/3d200a2a0c9a7df08945.png":"Item_100317.png","/map-media/1e61b30231bc8775a2cf.png":"Item_100306_Map.png","/map-media/2506bfd0b6175e6393c8.png":"Item_100318.png","/map-media/c0c0bf4c91b6489fc991.png":"Item_100319.png","/map-media/3b8066eba4a8b31c032b.png":"PetAvatar_3004_Map.png","/map-media/bd8508437110f6fb3d26.png":"PetAvatar_3001_Map.png","/map-media/6563c21f1e475f5f0bb2.png":"PetAvatar_3025_Map.png","/map-media/62c1555afc6b36fbf731.png":"PetAvatar_3003_Map.png","/map-media/403869b005f660f3dcd4.png":"PetAvatar_3002_Map.png","/map-media/9286e34e18cb54913fe0.png":"PetAvatar_3032_Map.png","/map-media/6c4628367a6afe4e5be1.png":"PetAvatar_3033_Map.png","/map-media/87deef65dbf3f8b69535.png":"PetAvatar_3046.png","/map-media/57b8b527822ac7a9abd7.png":"PetAvatar_3037.png","/map-media/6420092e3390c8434f88.png":"PetAvatar_3106.png","/map-media/96f12042a8fd557de8fa.png":"PetAvatar_3031.png","/map-media/04332c6152e1a40f2e4b.png":"PetAvatar_3367.png","/map-media/5970feef4a7218812f39.png":"PetAvatar_3192.png","/map-media/d456771399d032017380.png":"PetAvatar_3144_Map.png","/map-media/0b8f41b4516031376a03.png":"PetAvatar_3062.png","/map-media/25f94ece806f89d7a437.png":"PetAvatar_3005_Map.png","/map-media/8bc163f6fa6829dab554.png":"PetAvatar_3317.png","/map-media/0420411dc4b37add6288.png":"PetAvatar_3368.png","/map-media/00d655a4a7da8d6aab62.png":"PetAvatar_3157.png","/map-media/393dff13194a817cefe6.png":"Item_108062_Map.png","/map-media/00f1b64792bb6fdc507b.png":"PetAvatar_3165_Map.png","/map-media/6f32efb63db596c0ce8e.png":"PetAvatar_3166_Map.png","/map-media/47cf5bcfbb3fce5a0cdf.png":"PetAvatar_3167_Map.png","/map-media/82618b9575efb9d12796.png":"Item_108066_Map.png","/map-media/1f0c56b271eb6e914b39.png":"PetAvatar_3175_Map.png","/map-media/96881778940c7caec3d4.png":"PetAvatar_3176_Map.png","/map-media/3b705844e2750fb6ab3b.png":"PetAvatar_3177_Map.png","/map-media/5675a26fd3e948e50dda.png":"Item_108044_Map.png","/map-media/ed48342be001864cc115.png":"PetAvatar_3109_Map.png","/map-media/01d120a59d3fe232ae5a.png":"PetAvatar_3110_Map.png","/map-media/abf20cc7267f0a6a5d76.png":"PetAvatar_3111_Map.png","/map-media/767066264d816e714b5d.png":"Item_108179_Map.png","/map-media/1afba6c832878517d17c.png":"PetAvatar_3568_Map.png","/map-media/e69bc988b5859b0d1a45.png":"PetAvatar_3569_Map.png","/map-media/1e081226ee27bebe3ef4.png":"Item_108048_Map.png","/map-media/69af3be3c21cd6b8fa25.png":"PetAvatar_3121_Map.png","/map-media/96fbe5f0b107c6c98ef9.png":"PetAvatar_3122_Map.png","/map-media/d941a3fac7aa099365d1.png":"PetAvatar_3123_Map.png","/map-media/0ec98df9df5c043a3c41.png":"Item_108131_Map.png","/map-media/74f2d42b6f38d72e6aa0.png":"PetAvatar_3381_Map.png","/map-media/d7898d7242c3750ee75d.png":"Item_108077_Map.png","/map-media/c736b2991a1a33166862.png":"PetAvatar_3200.png","/map-media/f3248aff5e9a699ba63c.png":"PetAvatar_3201_Map.png","/map-media/422fcb0ec72c361a8ee8.png":"PetAvatar_3202_Map.png","/map-media/e3f93b921a0657df8f3f.png":"Item_108080_Map.png","/map-media/21a02a8f6f9734c9a069.png":"PetAvatar_3209_Map.png","/map-media/46e332deff205cb21909.png":"PetAvatar_3210_Map.png","/map-media/e566bdfc0fc5765bf12f.png":"Item_108059_Map.png","/map-media/65d7b9b8b809985134e2.png":"PetAvatar_3154_Map.png","/map-media/7b66adb8ab539c47ccb6.png":"PetAvatar_3155_Map.png","/map-media/a47b3594b1b9573a7259.png":"PetAvatar_3156_Map.png","/map-media/15359d6e84c4cdfc5146.png":"Item_108099_Map.png","/map-media/6f1f480f59c0152c0473.png":"PetAvatar_3257_Map.png","/map-media/aa1301ce3f9a22a8ae6d.png":"PetAvatar_3258_Map.png","/map-media/38dedcf42fbb7471fbff.png":"PetAvatar_3259_Map.png","/map-media/39aa3f31277569d0af18.png":"Item_108081_Map.png","/map-media/b81916a0617d162eeee6.png":"PetAvatar_3211_Map.png","/map-media/e482281cdc27ecdc8ef5.png":"PetAvatar_3412_Map.png","/map-media/2f5c07c5f7dbf5c6b67a.png":"Item_108162_Map.png","/map-media/c33793ec2934bb08bd4e.png":"PetAvatar_3444_Map.png","/map-media/f957bf50912675a68d78.png":"Item_108149_Map.png","/map-media/5cf8741f515ebfa566ea.png":"PetAvatar_3419_Map.png","/map-media/f2beb68071535d5d7d89.png":"PetAvatar_3420_Map.png","/map-media/4f44f86bcca634ac3c4e.png":"Item_108176_Map.png","/map-media/8223f8870841103b4bfa.png":"PetAvatar_3545_Map.png","/map-media/67e598deaa8c9e68f1df.png":"PetAvatar_3546_Map.png","/map-media/34119a54e11c3583749c.png":"Item_108213_Map.png","/map-media/c350c6aea76fc534eef3.png":"PetAvatar_3577_Map.png","/map-media/b68a812e9d7eb4b49167.png":"PetAvatar_3578_Map.png","/map-media/c6e693b3443fefe2081f.png":"Item_108037_Map.png","/map-media/0832879fe31748864c33.png":"PetAvatar_3083_Map.png","/map-media/3b3028b3121dd5b5ef6e.png":"PetAvatar_3084_Map.png","/map-media/dd3c5220eb8f117529d7.png":"PetAvatar_3085_Map.png","/map-media/1c72666689cbd17a68c9.png":"Item_108079_Map.png","/map-media/e3560099905cd1fc4c3e.png":"PetAvatar_3206_Map.png","/map-media/9139121f7f376aa4a0e3.png":"PetAvatar_3207_Map.png","/map-media/ab3a6e32a9cdec73eb18.png":"PetAvatar_3208_Map.png","/map-media/3ac09da69bbcf6c63bc8.png":"Item_7_Map.png","/map-media/190f747700e4d0829d5d.png":"Item_107131.png","/map-media/992a4fd970e9cb9a2d79.png":"Item_102002.png","/map-media/324329fc700079f35bca.png":"Item_107050.png","/map-media/fdd1a8fdf8ab0d07359e.png":"Item_102013.png","/map-media/7342617ed66c657c23ab.png":"Item_107034.png","/map-media/1669ae4e70af7d9699c3.png":"Item_102003.png","/map-media/2e2141d0b9ce2a15749a.png":"Item_107156.png","/map-media/88bea997d8c6f20d29c7.png":"Item_102015.png","/map-media/11bdfe6112b13ca074d5.png":"Item_107183.png","/map-media/a05b26895f0866e5c427.png":"Item_107122.png","/map-media/43287a87020cdd4be957.png":"Item_102007.png","/map-media/a2f4e4a55f7188bb466a.png":"Item_107187.png","/map-media/8d22a7061e36bd7c9853.png":"Item_102004.png","/map-media/ce4ff7d07613c6b63512.png":"Item_107207.png","/map-media/021932388eda607d4d52.png":"Item_102017.png","/map-media/c35b4db04b1f8fa417ba.png":"Item_107188.png","/map-media/1730e21588f085f55840.png":"Item_107058.png","/map-media/ed6a01ba37cf0a880793.png":"Item_102010.png","/map-media/f917c2f31bc851f46747.png":"Item_150066_Map.png","/map-media/ab6d722d5d68d3f08478.png":"Item_102006.png","/map-media/50aad10d8dbe4343c130.png":"Item_103028.png","/map-media/402fe2c906da42a0dcfe.png":"Item_102018.png","/map-media/5246eda480d8a1b8f59f.png":"Item_107175.png","/map-media/7c50ccc546224729ecfe.png":"Item_107007.png","/map-media/f342191d989247787ca1.png":"Item_102016.png","/map-media/8e313e96d5448eee567b.png":"Item_107178.png","/map-media/12101b13371e793d9fac.png":"Item_150077_Map.png","/map-media/982bb2e3f17808705891.png":"Item_102005_Map.png","/map-media/f33e3538792cbba16b2a.png":"Item_150101_Map.png","/map-media/87ec61fa605e4eab5bb6.png":"Item_150067_Map.png","/map-media/dff2ba1baed0e4cdb6ba.png":"Item_107023.png","/map-media/8139c40dce5fb8658d5d.png":"Item_107101.png","/map-media/c5d0ecb7650caaac78d9.png":"Item_20000005_Map.png","/map-media/394557ad57ba269294fb.png":"Item_150506_Map.png","/map-media/1cd5df57747ad0500af9.png":"Item_100283_Map.png","/map-media/ed760785a1233dc08591.png":"Item_1.png","/map-media/95c30caa811210ae3a03.png":"Item_20000007_Map.png","/map-media/d12b9495ed1592cc5e63.png":"Item_150520_Map.png","/map-media/a172dbd9aedb15b3ca69.png":"Item_100272.png","/map-media/5c3bba443f5f5fab75c4.png":"Item_20000003_Map.png","/map-media/88358abf88cc76b6a526.png":"Item_150503_Map.png","/map-media/8574ada63e828d2fb4d0.png":"Item_20000004_Map.png","/map-media/5141b394485175e62c1f.png":"Item_150502_Map.png","/map-media/066bdccecda9b1adfb4e.png":"Item_100271.png","/map-media/2c42ba59da57c9dc26d1.png":"Item_20000001_Map.png","/map-media/eefeddd645491fbfb8c1.png":"Item_150517_Map.png","/map-media/8ff6633bcb277a79213e.png":"Item_20000002_Map.png","/map-media/806a11c4cc6bc02594e6.png":"Item_150505_Map.png","/map-media/c4052635df65463bc2c9.png":"Item_100274.png","/map-media/0af81038827c01175e7e.png":"Item_20000006_Map.png","/map-media/6b364a33a7bcc523caf3.png":"Item_150508_Map.png","/map-media/eb34d8b8f6028884345e.png":"Item_20000010_Map.png","/map-media/8da938caeb5f5d8028ef.png":"Item_150509_Map.png","/map-media/ef1a9e2ad05f12ee939e.png":"Item_100263_Map.png","/map-media/6521d3ddf35b49f34899.png":"Item_20000012_Map.png","/map-media/f1236dd85e757c8af911.png":"Item_150518_Map.png","/map-media/f528e7a7d4eda6385ba4.png":"Item_100275_Map.png","/map-media/2848e937de85e925a834.png":"Item_20000009_Map.png","/map-media/74730f6da41b6be0425b.png":"Item_150522_Map.png","/map-media/e3e30cff7037901aa2eb.png":"Item_20000015_Map.png","/map-media/f5572b11bd87a2591444.png":"Item_150516_Map.png","/map-media/528dc0c88da65dbb8baa.png":"Item_20000014_Map.png","/map-media/70296d27f60c4ca03ab6.png":"Item_150501_Map.png","/map-media/75491a96140d8571a006.png":"Item_20000017_Map.png","/map-media/753c6a69b6a6f3d50e58.png":"Item_150521_Map.png","/map-media/074f53795974f7181926.png":"Item_100284_Map.png","/map-media/74c04e0902f15bf95727.png":"Item_20000018_Map.png","/map-media/e3eaed7ac8ed022066b6.png":"Item_150504_Map.png","/map-media/765ed11f17de4cdf0356.png":"Item_100273_Map.png","/map-media/69388d68f81518f74e3a.png":"Item_20000011_Map.png","/map-media/64c0357033c89bce4949.png":"Item_150500_Map.png","/map-media/dd82b99008704c1cc435.png":"Item_20000013_Map.png","/map-media/d01eb877edc34172a071.png":"Item_150507_Map.png","/map-media/463e5546832f778d2949.png":"Item_20000016_Map.png","/map-media/ef584a2d8f988005a2b4.png":"Item_151041.png","/map-media/ae20675daf7bdedaaeeb.png":"Item_100262_Map.png","/map-media/e9a6d24a3e31afa1447c.png":"Item_20000008_Map.png","/map-media/5d46c358ec58b3b48e98.png":"Item_151043.png","/map-media/084483d0fa15be0d52af.png":"PetAvatar_3055.png","/map-media/1e5312acedd3a8975b44.png":"PetAvatar_3093.png","/map-media/418ef4e4dcbf0942f338.png":"PetAvatar_3215.png","/map-media/5a0eeb384bf60f881c2b.png":"PetAvatar_3330.png","/map-media/0593792d28bf1582a2e1.png":"PetAvatar_3509.png","/map-media/e3350be65907af5e1317.png":"PetAvatar_3010.png","/map-media/4c721698dbc60f514f2e.png":"PetAvatar_3406.png","/map-media/f708fc226038cb1f0554.png":"PetAvatar_3484_Map.png","/map-media/0f9c19e79e7248ef19d9.png":"PetAvatar_3239.png","/map-media/a3593ac2023638beeaf0.png":"PetAvatar_3465_Map.png","/map-media/ba9c2275dc62fe699868.png":"PetAvatar_3458_Map.png","/map-media/6c693d106a02d847a6d8.png":"PetAvatar_3459_Map.png","/map-media/6f5a8c74b73f4c832ec1.png":"PetAvatar_3460_Map.png","/map-media/0b0c45e50da37aeba01c.png":"PetAvatar_3461_Map.png","/map-media/8715bf70a1d6deebc449.png":"PetAvatar_3462_Map.png","/map-media/070e95e99f54343540cf.png":"PetAvatar_3463_Map.png","/map-media/a97c4afd98e90ef6fa0d.png":"PetAvatar_3526_Map.png","/map-media/ca0b953b53ef2cf61358.png":"PetAvatar_3527_Map.png","/map-media/5b1dc1777d6810142d41.png":"PetAvatar_3528_Map.png","/map-media/25cabf84ef5c0d131866.png":"PetAvatar_3357.png","/map-media/a395b5ea69a7d8450038.png":"PetAvatar_3431.png","/map-media/658e8a4f03acae3e9e33.png":"PetAvatar_3384.png","/map-media/93f6e6cca7bd4771a97b.png":"Item_102009_Map.png","/map-media/ba14ecc373c60373fb73.png":"PetAvatar_3508_Map.png","/map-media/981f9c6123e31431d5d0.png":"PetAvatar_3551_Map.png","/map-media/2f1c6bd8b582226fd3c4.png":"PetAvatar_3555_Map.png","/map-media/dcab6678faedbff1114b.png":"PetAvatar_3534_Map.png","/map-media/a0d4b39a811a04682bb5.png":"PetAvatar_3127_Map.png","/map-media/290497f9ba062a6facb0.png":"Item_102012_Map.png","/map-media/c87478ab35b3bfe381bf.png":"PetAvatar_3559_Map.png","/map-media/17921b23ac8f3ec0c868.png":"PetAvatar_3553_Map.png","/map-media/6913eae4efa255891058.png":"PetAvatar_3151.png","/map-media/cd8e2eda7c9aefc66128.png":"PetAvatar_3040.png","/map-media/0a1e4ecac1a2560986f2.png":"PetAvatar_3289.png","/map-media/43dbfb2d63d5468f1633.png":"PetAvatar_3499_Map.png","/map-media/16ff916edc86cbd059ea.png":"PetAvatar_3020.png","/map-media/b090d8fb3d01c6e5b086.png":"PetAvatar_3026.png","/map-media/2f90475558b82e2f126d.png":"PetAvatar_3410.png","/map-media/19b273b930ca6c08a40e.png":"PetAvatar_3536_Map.png","/map-media/f727fffc4a1aca6557d2.png":"PetAvatar_3008.png","/map-media/853e10013a10abff0fb0.png":"PetAvatar_3195_Map.png","/map-media/e540fad0606c08c9f3f4.png":"PetAvatar_3298_Map.png","/map-media/a44bca8b2a30d579783c.png":"PetAvatar_3072.png","/map-media/505ddad3ef58ab88bfea.png":"PetAvatar_3034.png","/map-media/72cfd961ceec3b9caee0.png":"PetAvatar_3029.png","/map-media/ebf7b8570d03d30c68ab.png":"PetAvatar_3043.png","/map-media/0c49483b90ad13fea8ee.png":"PetAvatar_3454_Map.png","/map-media/9cb1e4aef5001c16b4e4.png":"PetAvatar_3378.png","/map-media/85bb8edcbcd8a85ca1e1.png":"PetAvatar_3704.png","/map-media/ff6674194fcae3248c69.png":"PetAvatar_3038.png","/map-media/22e0cf9aa3a4bfd3853f.png":"PetAvatar_3492_Map.png","/map-media/502e77a1a3074f3aa673.png":"PetAvatar_3539_Map.png","/map-media/ac2d1342951362a0fa8d.png":"PetAvatar_3529_Map.png","/map-media/0ae6ee609791473eea74.png":"PetAvatar_3115.png","/map-media/04af18a38daf2193e99f.png":"PetAvatar_3069.png","/map-media/34b72decd292a6096e64.png":"PetAvatar_3344.png","/map-media/473897f876efd30801cf.png":"PetAvatar_3521_Map.png","/map-media/aaae83ebe95c0be9558e.png":"PetAvatar_3193.png","/map-media/02b10b0b41c805d33c42.png":"PetAvatar_3467_Map.png","/map-media/b9d1ee7e63585fe273f0.png":"PetAvatar_3012.png","/map-media/07eb10f0d0a2c8471c14.png":"PetAvatar_3237.png","/map-media/8d75ea3869a9ed5d28c1.png":"PetAvatar_3086.png","/map-media/807d3e927e142963d556.png":"PetAvatar_3112_Map.png","/map-media/d71006058483c1afbb58.png":"PetAvatar_3130.png","/map-media/4b2314a29c1a8841dda9.png":"Item_102014.png","/map-media/4ffe857fdabc736cc621.png":"PetAvatar_3014_Map.png","/map-media/b9c21ce735b4d6308db0.png":"PetAvatar_3188.png","/map-media/3ba0fb84b11170b78997.png":"PetAvatar_3190.png","/map-media/5680602bba40dbe893bd.png":"PetAvatar_3584_Map.png","/map-media/a31bb31f13bea93bba29.png":"PetAvatar_3432.png","/map-media/9d5321e7f06aac941283.png":"PetAvatar_3307.png","/map-media/8e12f70fda74460c862c.png":"PetAvatar_3136.png","/map-media/79e97ff76b7c15dcf3a6.png":"PetAvatar_3225.png","/map-media/8d77279741f8adfdda91.png":"PetAvatar_3618_Map.png","/map-media/446e77b39912057a8c17.png":"PetAvatar_3533_Map.png","/map-media/445dcebfe22fad63e531.png":"PetAvatar_3279_Map.png","/map-media/8a5fee9a64ebce3694b1.png":"PetAvatar_3281_Map.png","/map-media/d9312024bf7853fc6754.png":"PetAvatar_3280_Map.png","/map-media/1a807adad85a18bd0030.png":"PetAvatar_3299_Map.png","/map-media/b56cc5ce3ce70c7360bc.png":"PetAvatar_3297_Map.png","/map-media/0a89b68f89f3ddef38b6.png":"PetAvatar_3017.png","/map-media/5045493aac8257751100.png":"PetAvatar_3060.png","/map-media/2647cc96c92c0589b046.png":"PetAvatar_3438.png","/map-media/fce20fbd8db40a670f0a.png":"PetAvatar_3250.png","/map-media/0994a75a577836369d41.png":"Item_102001.png","/map-media/e0d11adb9d984dbc7871.png":"PetAvatar_3315.png","/map-media/f7eea2da49f3527b0b5b.png":"Item_102008_Map.png","/map-media/cbcb50580350b740bfcc.png":"PetAvatar_3262.png","/map-media/7ce9d30fba9ba3a5a727.png":"PetAvatar_3036.png","/map-media/2d076844163568a576ae.png":"PetAvatar_3490_Map.png","/map-media/9ddf803a18f42492a3f0.png":"PetAvatar_3376.png","/map-media/810682b1656704296a76.png":"PetAvatar_3178.png","/map-media/d84d3ce449e902f498f7.png":"PetAvatar_3098_Map.png","/map-media/f136e780647ba8e8388c.png":"PetAvatar_3172.png","/map-media/70d5ade18c7bf9a095c1.png":"PetAvatar_3103.png","/map-media/6a17aa12a08d2bc5881a.png":"PetAvatar_3045.png","/map-media/db80a801a6223273dda3.png":"PetAvatar_3070.png","/map-media/23949bc831a221f780f4.png":"PetAvatar_3227.png","/map-media/3034286bd0cf38848ec2.png":"Item_102011_Map.png","/map-media/4db4be7aac8ba73283d0.png":"PetAvatar_3333.png","/map-media/f3bb9e444c9ad817f967.png":"PetAvatar_3118_Map.png","/map-media/a93e8c370142960e152b.png":"PetAvatar_3028.png","/map-media/7c93a83bec81ffae8a7c.png":"Item_100425_Map.png","/map-media/3af9623387e2f7096da2.png":"Item_600010.png","/map-media/0fd37b4eb2483f08ac1b.png":"Item_100533.png","/map-media/1b49253865368c423c3d.png":"Item_108014_Map.png","/map-media/3ba388134ce9da5497c4.png":"PetAvatar_3282.png","/map-media/a1a1d98146ae91f4ef0c.png":"PetAvatar_3285_Map.png","/map-media/9314133331b44870c9b4.png":"Item_108009_Map.png","/map-media/44ce98f51f6e1193b947.png":"Item_108012_Map.png","/map-media/d2f324bea53cdfb5d6b8.png":"PetAvatar_3455_Map.png","/map-media/923db95619a42e994282.png":"PetAvatar_3456_Map.png","/map-media/7345550e313ac8c48900.png":"Item_108011_Map.png","/map-media/89bf681dd706448848c4.png":"PetAvatar_3300_Map.png","/map-media/d1a2e8463197c88766d3.png":"PetAvatar_3303_Map.png","/map-media/eedffca414f71baae9fb.png":"Item_108019_Map.png","/map-media/316752a64954152add67.png":"PetAvatar_3290_Map.png","/map-media/be3d1e099381f0920502.png":"PetAvatar_3293_Map.png","/map-media/824e28e7292108cecc6d.png":"PetAvatar_3296_Map.png","/map-media/18828f21c14ba3378c80.png":"Item_108152_Map.png","/map-media/5fbc2aea0bc41a86abc2.png":"PetAvatar_3440.png","/map-media/6790628685a9537f8f74.png":"PetAvatar_3441_Map.png","/map-media/60047e111d267711a79a.png":"Item_108074_Map.png","/map-media/1110ecc038c3e8a6977c.png":"PetAvatar_3442_Map.png","/map-media/ee72917103b81b245cb3.png":"PetAvatar_3443_Map.png","/map-media/d3f1173be4a1fe642032.png":"PetAvatar_3284_Map.png","/map-media/17511911289f6f3e7964.png":"PetAvatar_3287_Map.png","/map-media/df6e9f748003fe9ade35.png":"PetAvatar_3292_Map.png","/map-media/e593e3de7c6bef6d1a47.png":"PetAvatar_3295_Map.png","/map-media/8d58c465700f5efd0de4.png":"Item_100534.png","/map-media/0334ac9d1d3e1f234501.png":"PetAvatar_3283.png","/map-media/93fc9156d1bac9cafc7c.png":"PetAvatar_3286.png","/map-media/f5710849a52699c93c1f.png":"PetAvatar_3301_Map.png","/map-media/1ed2882d58e7783a1222.png":"PetAvatar_3304_Map.png","/map-media/3f69fb397e1904689c41.png":"PetAvatar_3302_Map.png","/map-media/6605ae3584a0d270b8d7.png":"PetAvatar_3305_Map.png","/map-media/150811607b57917bc541.png":"Item_108177_Map.png","/map-media/f1873128adc3a42ded22.png":"PetAvatar_3556_Map.png","/map-media/c1f41a7d697c05c49ff9.png":"Item_108180_Map.png","/map-media/04c304c27a03b5a655a3.png":"PetAvatar_3585_Map.png","/map-media/59ef8db0e4ce2e072f1b.png":"Item_108129_Map.png","/map-media/ee12cc4e40e57e3b66d1.png":"PetAvatar_3496_Map.png","/map-media/eaa7f4d1b68f7c42cb2b.png":"PetAvatar_3497.png","/map-media/643816963990c49d1033.png":"PetAvatar_3498_Map.png","/map-media/78444b3df06ccd2503d9.png":"Item_108170_Map.png","/map-media/3403afa1640079744317.png":"PetAvatar_3511_Map.png","/map-media/3263e2407564894efb01.png":"PetAvatar_3512.png","/map-media/75a0df20b8ed5bd2fbc7.png":"PetAvatar_3513_Map.png","/map-media/3942fcf0f1adfa734b40.png":"Item_108174_Map.png","/map-media/39bb8870912cb937f427.png":"PetAvatar_3540_Map.png","/map-media/559e4f5da02496e65bd7.png":"Item_108161_Map.png","/map-media/aefe5b8f8b7c0cff3a36.png":"Item_108120_Map.png","/map-media/50e20039edb19ea516cc.png":"PetAvatar_3475_Map.png","/map-media/7f7260172cb6094568ab.png":"PetAvatar_3476.png","/map-media/57783b8c8d1caa1d1645.png":"PetAvatar_3477_Map.png","/map-media/205a91fd03102515d6f4.png":"Item_108050_Map.png","/map-media/368a2fb387854d1aa3fa.png":"PetAvatar_3468_Map.png","/map-media/b91190be29fe28ea51bf.png":"PetAvatar_3469_Map.png","/map-media/f5cd601f53a9b7e2afd5.png":"PetAvatar_3433_Map.png","/map-media/f513b343fa2702874682.png":"Item_100422_Map.png","/map-media/f55bc9ec3bcc9eb11dd0.png":"Item_100423_Map.png","/map-media/162a7bfb49e811cbf181.png":"Item_100002_Map.png","/map-media/9aaa554f1d0a9e76b1e5.png":"Item_100136_Map.png","/map-media/6c7cdc2bf1b4a74d3a14.png":"Item_107108_Map.png","/map-media/facc3847f565b4764807.png":"Item_107106_Map.png","/map-media/a9a32b0291dd5a976dc6.png":"Item_107107_Map.png","/map-media/94b079fd285d1da65797.png":"Item_150520_Map.png","/map-media/9516ec53cd5ed14efa37.png":"Item_100123_Map.png","/map-media/00544a603f9758dae137.png":"Item_100628_Map.png","/map-media/79798c419c7a9ec80a32.png":"Item_100676_Map.png","/map-media/5f4ec3a5dcadac062b7b.png":"Item_100675_Map.png","/map-media/924ff6fdf67a6d488b88.png":"Item_100677_Map.png","/map-media/0847fb3b73649bc87407.png":"Item_260031_Map.png","/map-media/9a758907e12992cf6e86.png":"Item_260031_Map.png","/map-media/03bd46d91e68a3bb82c1.png":"Item_260031_Map.png","/map-media/af4665a14e463560b460.png":"Item_260031_Map.png","/map-media/e4551bd2a23b914a15a0.png":"Item_100125_Map.png","/map-media/5f3297a0c01361e9bf9a.png":"Item_100255_Map.png","/map-media/2e7ff96efed739812b2b.png":"Item_100010_Map.png","/map-media/c0c0a15d411738066ff5.png":"Item_300119.png","/map-media/615408bc92e25590b8c5.png":"Item_100130_Map.png","/map-media/997e881e430faab04020.png":"Item_300119.png","/map-media/bf6fdcec4bc74317c7d5.png":"Item_300119.png","/map-media/c5a93b378275890fda43.png":"Item_300119.png","/map-media/316a9bd7d3022000d344.png":"Item_102022_Map.png","/map-media/2de34af7c1929795bbd9.png":"Item_102023_Map.png","/map-media/1a538536bd074a4000f6.png":"Item_79_Map.png","/map-media/98b62cad1c4be2f4be65.png":"PetAvatar_3380.png","/map-media/665fed9eae2fd4ad218d.png":"PetAvatar_3039.png","/map-media/8f28756cf23422637067.png":"PetAvatar_3379_Map.png","/map-media/8fa84c2d7850a3802fcd.png":"PetAvatar_3288.png","/map-media/77701cd5c07599084391.png":"PetAvatar_3291.png","/map-media/2e8e93aefce35e992800.png":"PetAvatar_3294.png","/map-media/19cf6d6a5bc0b7586391.png":"PetAvatar_3756.png","/map-media/89fcbcbae48cc0dcb13c.png":"PetAvatar_3755.png","/map-media/c5aa3559c63d1fe48146.png":"PetAvatar_3754.png","/map-media/21f1d3327cabb18e3aae.png":"PetAvatar_3113.png","/map-media/d1e15f63c65facc25fe8.png":"PetAvatar_3749.png","/map-media/0ac004879390157d1999.png":"PetAvatar_3114.png","/map-media/91835a3920050e33acba.png":"PetAvatar_3451_Map.png","/map-media/8c7da7da39554fc53de6.png":"PetAvatar_3403.png","/map-media/8da1364e679f542785de.png":"PetAvatar_3449_Map.png","/map-media/df0bf981c5721f0bad7d.png":"PetAvatar_3402.png","/map-media/e63b4fd81457a6d14c89.png":"PetAvatar_3404.png","/map-media/c4f76c3f9cd552edc78e.png":"PetAvatar_3255.png","/map-media/d0bddfc4c8bf615973c4.png":"PetAvatar_3547_Map.png","/map-media/ce92877207f5d1dc3c44.png":"PetAvatar_3067.png","/map-media/01e984c4d007535044ef.png":"PetAvatar_3238.png","/map-media/5eb1f0fcbedeb677db82.png":"PetAvatar_3535_Map.png","/map-media/d5aa7052a5ce317e7c04.png":"PetAvatar_3550_Map.png","/map-media/ccb502d195d7bd5a381f.png":"PetAvatar_3557_Map.png","/map-media/953f8a8535d3d5079803.png":"PetAvatar_3137_Map.png","/map-media/a2cb6853e24614d3cd12.png":"PetAvatar_3095.png","/map-media/149e18cab6d2bbb1e61c.png":"PetAvatar_3094_Map.png","/map-media/5f58a9baa538889fa267.png":"PetAvatar_3041_Map.png","/map-media/812f5cdb63abc92394d9.png":"PetAvatar_3042.png","/map-media/6eb64d3f498de6131787.png":"PetAvatar_3056.png","/map-media/3a5964fd38c7c8225d62.png":"PetAvatar_3145.png","/map-media/3a5a0107ca4d610296b7.png":"PetAvatar_3147.png","/map-media/296cd6542c8a1942de93.png":"PetAvatar_3146.png","/map-media/237c4746c87d685d29c7.png":"PetAvatar_3099_Map.png","/map-media/160e9c95b66e0c506deb.png":"PetAvatar_3087_Map.png","/map-media/0635e2305caa1a02d145.png":"PetAvatar_3078_Map.png","/map-media/9914d2a11565492b28d0.png":"PetAvatar_3088.png","/map-media/b83e4439ad043a536c76.png":"PetAvatar_3276.png","/map-media/74cd70be6ab41ef8ab08.png":"PetAvatar_3346_Map.png","/map-media/649aca73dd72401edc67.png":"PetAvatar_3345.png","/map-media/337311c8811a8c11dc97.png":"PetAvatar_3116.png","/map-media/9343ffd181d7dd17aa01.png":"PetAvatar_3100_Map.png","/map-media/3263c3954335251d5b23.png":"PetAvatar_3022_Map.png","/map-media/be0e043581c3fea248d8.png":"PetAvatar_3021.png","/map-media/9822262423ecff9eb5e0.png":"PetAvatar_3079.png","/map-media/a051050cec28e966db65.png":"PetAvatar_3277_Map.png","/map-media/21e4843449ec4f382808.png":"PetAvatar_3571_Map.png","/map-media/16ea159ed949de896a0e.png":"PetAvatar_3128_Map.png","/map-media/d8e37d054039eab673d5.png":"PetAvatar_3538_Map.png","/map-media/1552a84db99daf3e6016.png":"PetAvatar_3740.png","/map-media/ff10683a35253b260302.png":"PetAvatar_3081.png","/map-media/cd7cf7c48cee51411cf6.png":"PetAvatar_3170.png","/map-media/56aaa8cdecbcbedd940e.png":"PetAvatar_3082.png","/map-media/e3a434ba65fa57de3276.png":"PetAvatar_3705.png","/map-media/d8ab790b11404cf484b1.png":"PetAvatar_3483_Map.png","/map-media/18b3f924f654226ce781.png":"PetAvatar_3537_Map.png","/map-media/1807db0746c78aeb3009.png":"PetAvatar_3377.png","/map-media/2825d71991b1fa6953ac.png":"PetAvatar_3434.png","/map-media/f8bad3dea2c791551b21.png":"PetAvatar_3342.png","/map-media/5b3a8bfd8bf9225ce627.png":"PetAvatar_3174.png","/map-media/f73eef20815f297ef23e.png":"PetAvatar_3341.png","/map-media/9a3c4795b7d1d518c3cf.png":"PetAvatar_3343.png","/map-media/a55498e120a8171e611c.png":"PetAvatar_3153.png","/map-media/6661d69d43e2b7e23cd5.png":"PetAvatar_3348.png","/map-media/2ccb63bcc8fdff8ebe9f.png":"PetAvatar_3152_Map.png","/map-media/520796dba836e37df283.png":"PetAvatar_3323.png","/map-media/b7c138b15cdde370659b.png":"PetAvatar_3011.png","/map-media/4e3aed6b74a5b0af8cff.png":"PetAvatar_3491_Map.png","/map-media/5c595123b78b5ed4babd.png":"PetAvatar_3183.png","/map-media/f143ba791b20367df9e0.png":"PetAvatar_3322.png","/map-media/f395a3489a857239ac24.png":"PetAvatar_3184.png","/map-media/842669b44009f05c816a.png":"PetAvatar_3347.png","/map-media/7fecf5001c782ce9b691.png":"PetAvatar_3321.png","/map-media/927ba9762cdc20608c6e.png":"PetAvatar_3185.png","/map-media/f7cd3e5f6fb023216574.png":"PetAvatar_3349.png","/map-media/8801d53885b6796af7be.png":"PetAvatar_3582_Map.png","/map-media/0a0ee07cef60d9cc21cb.png":"PetAvatar_3510_Map.png","/map-media/17d498023e0b2209aca4.png":"PetAvatar_3131.png","/map-media/021e7bc048a4e27620aa.png":"PetAvatar_3583.png","/map-media/2850e3445dc4a5d834b3.png":"PetAvatar_3216.png","/map-media/6cb746457d55e0323292.png":"PetAvatar_3120.png","/map-media/5cbdcfc84d88a0b46999.png":"PetAvatar_3119.png","/map-media/75244b71903e0215f261.png":"PetAvatar_3132.png","/map-media/8ff107018152b54ae00b.png":"PetAvatar_3506_Map.png","/map-media/14e8d07fe1853c087de3.png":"PetAvatar_3331_Map.png","/map-media/e705b8a93efc2c9441b0.png":"PetAvatar_3332.png","/map-media/e5444759af36a7a25426.png":"PetAvatar_3143.png","/map-media/96e09e0ea689a60d0d55.png":"PetAvatar_3266.png","/map-media/a71016b54153a7a82f3b.png":"PetAvatar_3267_Map.png","/map-media/7dd983b3d27ed2177c08.png":"PetAvatar_3074_Map.png","/map-media/0fef7ff80877679d2235.png":"PetAvatar_3073.png","/map-media/eedf53a1a31fb58dc2a0.png":"PetAvatar_3194.png","/map-media/6d6bfcc31c264df7bf07.png":"PetAvatar_3091_Map.png","/map-media/f84fd7c5364e310e6723.png":"PetAvatar_3090.png","/map-media/19f222fe83f0930e8842.png":"PetAvatar_3092.png","/map-media/c6c6f0a480328259c94f.png":"PetAvatar_3108_Map.png","/map-media/7d4f93b6b6b2384653ba.png":"PetAvatar_3107_Map.png","/map-media/f242f40ea2b64d252d53.png":"PetAvatar_3179_Map.png","/map-media/623dd3780468ff6393fe.png":"PetAvatar_3466.png","/map-media/0279f354a7ce174fa479.png":"PetAvatar_3240.png","/map-media/9fb614de1c891e24ed96.png":"PetAvatar_3350.png","/map-media/594f03febe6c6aa2283e.png":"PetAvatar_3334.png","/map-media/1e7de976e991f5b41159.png":"PetAvatar_3117.png","/map-media/4da83e525846725205ea.png":"PetAvatar_3751.png","/map-media/ca4a6449653407577571.png":"PetAvatar_3750.png","/map-media/f167f141428bf13a13fd.png":"PetAvatar_3080_Map.png","/map-media/0b4d3919ae71796a0c4f.png":"PetAvatar_3047.png","/map-media/3e02917505ea06e51104.png":"PetAvatar_3335.png","/map-media/141db7a4dd9879629604.png":"PetAvatar_3353.png","/map-media/6b3dc81ebbb918e9d28c.png":"PetAvatar_3352.png","/map-media/a76bc508e27ba9a6d0a4.png":"PetAvatar_3351.png","/map-media/94a13a61e2869b3471b7.png":"PetAvatar_3263.png","/map-media/0277c87607ad34a9bf38.png":"PetAvatar_3173_Map.png","/map-media/2f2767b16bed02e308ff.png":"PetAvatar_3385.png","/map-media/2ea2295ec303ab7ff4d6.png":"PetAvatar_3251.png","/map-media/4bd61ad0a4c77ddeb274.png":"PetAvatar_3252.png","/map-media/2abc3a4b5844320ba1d3.png":"PetAvatar_3386_Map.png","/map-media/fd739d250bfdbb723d63.png":"PetAvatar_3268.png","/map-media/98839f2e3fc997fee78c.png":"PetAvatar_3269.png","/map-media/10f2370ec515d3c4e2af.png":"PetAvatar_3241.png","/map-media/d9dc0cd5674acd60a0b4.png":"PetAvatar_3358_Map.png","/map-media/7035f5ac4ebd3c17d64a.png":"PetAvatar_3018.png","/map-media/9eb81ca62b631a1a1d60.png":"PetAvatar_3189.png","/map-media/010486991ff5756aa88a.png":"PetAvatar_3061_Map.png","/map-media/bd97b5292d0a102475c3.png":"PetAvatar_3196.png","/map-media/7466992dc0d5f6b30afd.png":"PetAvatar_3407_Map.png","/map-media/6694702a464eef31bf3d.png":"PetAvatar_3226.png","/map-media/40d4a5a136cd54eecfee.png":"PetAvatar_3619_Map.png","/map-media/4b28618fdbff884350f5.png":"PetAvatar_3058.png","/map-media/071b274ae7dfdbd5e565.png":"PetAvatar_3139.png","/map-media/e67e12433239d5dff96b.png":"PetAvatar_3439.png","/map-media/06792f6ba8b5d952493a.png":"PetAvatar_3316.png","/map-media/e1bbfd0335855490c6a7.png":"PetAvatar_3757.png","/map-media/6c5ac1b99236f9aa60ac.png":"PetAvatar_3063_Map.png","/map-media/ad1cf566e585a00b704f.png":"PetAvatar_3552_Map.png","/map-media/762e05aa17e97d72f28d.png":"PetAvatar_3129_Map.png","/map-media/93dc07d417395bbbafcb.png":"PetAvatar_3558_Map.png","/map-media/5caf8d8932ac0c01eb4c.png":"PetAvatar_3375_Map.png","/map-media/f9bfb84f3b2b8cb6a94d.png":"PetAvatar_3554_Map.png","/map-media/c93e1c05b0f9a2329c5b.png":"PetAvatar_3071.png","/map-media/78213553c3a60b04d1a8.png":"PetAvatar_3140.png","/map-media/d34ff766fb3e94d894f3.png":"PetAvatar_3101_Map.png","/map-media/9476ecd5aec4e8adbc46.png":"PetAvatar_3741.png","/map-media/4ed8e066b41007639286.png":"PetAvatar_3044.png","/map-media/f5d4d350cac35e607dbb.png":"PetAvatar_3030_Map.png","/map-media/5b4cfd19b8149a555bc2.png":"PetAvatar_3035.png","/map-media/15b6bb210331d7e38162.png":"PetAvatar_3059_Map.png","/map-media/a27ff17a90fd7ce9d470.png":"PetAvatar_3027.png","/map-media/18485d4bdb56efc1af86.png":"PetAvatar_3050.png","/map-media/d24ab777658951a221e8.png":"PetAvatar_3105.png","/map-media/7797cb3496a9f7c4ff2a.png":"PetAvatar_3104.png","/map-media/501ef7a834ee7a43a0eb.png":"PetAvatar_3411.png","/map-media/3aebd39d38fae6475fcd.png":"PetAvatar_3075_Map.png","/map-media/cfb793f55e4a2555af88.png":"PetAvatar_3278.png","/map-media/ebfbf1012ac8de51d176.png":"PetAvatar_3435_Map.png","/map-media/6ebe409d3282bc617825.png":"PetAvatar_3019.png","/map-media/ffa48ea9052eadbfaa0f.png":"PetAvatar_3191.png","/map-media/923b31e3babab0a14676.png":"PetAvatar_3066.png","/map-media/7fb685cfb264d5240422.png":"Item_100734_Map.png","/map-media/bfc3f3a1609cd60b460c.png":"Item_100735_Map.png","/map-media/31afbe38ab12bcc91262.png":"Item_100735_Map.png","/map-media/1e96bc0556b11333561d.png":"Item_260001.png","/map-media/c068d5f04845e8fa7ef9.png":"Item_720001.png","/map-media/c8b79e991eadc732ca6d.png":"Item_720001.png","/map-media/5a848c04f44c5405ef11.png":"Item_720002.png","/map-media/57b19536c9d2a7ab6a1d.png":"Item_720002.png","/map-media/e200954efbb49084b434.png":"Item_720005.png","/map-media/8d4a3d0d1d778048c7ed.png":"Item_720005.png","/map-media/c359b0e38c11a7e3cfa2.png":"Item_720029.png","/map-media/93057c949984c3c24a58.png":"Item_720029.png","/map-media/32a6d2134f156cf11cff.png":"Item_720016.png","/map-media/dcefdea43ade56867aeb.png":"Item_720008.png","/map-media/eb99e4e92d2bdd9a8d95.png":"Item_720008.png","/map-media/a4c5c79cc545844efdf7.png":"Item_720025.png","/map-media/cb5a0e3a24e6e22042c5.png":"Item_720025.png","/map-media/a8629340415aed182e31.png":"Item_720009_Map.png","/map-media/7aeb0aa7ba342ca48532.png":"Item_720010_Map.png","/map-media/70bade096968caa3c323.png":"Item_260001.png","/map-media/7d99357fe3bfb8908d8d.png":"Item_720011_Map.png","/map-media/c1e2ea1e4178741ade51.png":"Item_260001.png","/map-media/98951db1882a80e9e751.png":"Item_100723_Map.png","/map-media/090a59180a780f709787.png":"Item_720003.png","/map-media/a9db337b12e79a58afe3.png":"Item_720003.png","/map-media/50bba532e4ed142d92ac.png":"Item_720004.png","/map-media/f45868d00fbd8a6bbfe4.png":"Item_720004.png","/map-media/c71a4dacb583333615fe.png":"Item_720027.png","/map-media/6f492e9f67afd0616b8d.png":"Item_720027.png","/map-media/034b6d8b0242ac390699.png":"Item_720007.png","/map-media/8bc75727b612de4e9bc8.png":"Item_720007.png","/map-media/28437983ff85ed4c516e.png":"Item_100424.png","/map-media/44c7325aa8cedb40bcff.png":"Item_280000_Map.png","/map-media/05ecfc0fadcf1aa47613.png":"Item_100737.png","/map-media/69fd142a724a65399685.png":"Item_100738.png","/map-media/3b9dd1d4bcf536034a01.png":"Item_100739.png","/map-media/9c8c7182e6d2eb56190c.png":"Item_100737.png","/map-media/7179f59d84bfdf44edd9.png":"Item_100738.png","/map-media/15dd4cce8e8aee67eb46.png":"Item_100739.png","/map-media/95ee463a7b0ebda81ec8.png":"Item_107239.png","/map-media/ae89346946e55b523318.png":"Item_107237.png","/map-media/0d7eee947e6565ceaf5e.png":"Item_107065.png","/map-media/7d37ed5a6f86e9bbfdb3.png":"Item_107140.png","/map-media/1b25e2490fc05f6e7028.png":"Item_107206.png","/map-media/9d5ee20025a160ecd5a4.png":"Item_111001.png","/map-media/b7c491142b43b4f9dbd3.png":"Item_111001.png","/map-media/57b68324d9d17c43fe54.png":"Item_111001.png","/map-media/d2c447b8369511d3ab82.png":"Item_111001.png","/map-media/d8492ec5a320ec1ba96b.png":"Item_111001.png","/map-media/e72062c5846940ea0633.png":"Item_100700.png","/map-media/f04e2eaa508a1b491d2f.png":"Item_100856.png","/map-media/c8ae3aee2ee5a0abe8a2.png":"Item_100858.png","/map-media/db3053c2e5ac7672d6c4.png":"Item_100851.png","/map-media/af5cfcca518376172b6d.png":"Item_350001_Map.png","/map-media/8e2a8a652ade99aa2307.png":"Item_350002_Map.png","/map-media/b5b4f9b5387dab046954.png":"Item_350003_Map.png","/map-media/a78916beb1c28ac83ac0.png":"Item_350004_Map.png","/map-media/b4d3b937a71d570506dd.png":"Item_350007_Map.png","/map-media/8665a6ff00823aa3e9a7.png":"Item_350012_Map.png","/map-media/47097c0d72a35c3abef4.png":"Item_350017_Map.png","/map-media/2b6d3cc26fb3d1ce9d5e.png":"Item_350022_Map.png","/map-media/fc77d32a0978307fab31.png":"Item_350005_Map.png","/map-media/4604d6f1ec92c0c1478c.png":"Item_350010_Map.png","/map-media/c6cae1d76f8977c7c473.png":"Item_350020_Map.png","/map-media/0c9972dfe67c46e01ae1.png":"Item_350015_Map.png","/map-media/21fb7c2bbbeb2e674b0f.png":"Item_350024_Map.png","/map-media/1ac56cbc6fbcc9d1aa45.png":"Item_350019_Map.png","/map-media/c4039857e9b740b2baab.png":"Item_350009_Map.png","/map-media/bde5571ef7e85d57d38d.png":"Item_350014_Map.png","/map-media/53bff7928df019b055b8.png":"Item_350018_Map.png","/map-media/aefea63074b2dd495911.png":"Item_350013_Map.png","/map-media/030add33304d184cd84b.png":"Item_350008_Map.png","/map-media/31646beadeb3fc9f2d8c.png":"Item_350023_Map.png","/map-media/7d6b95830cb5cdaea38f.png":"Item_350006_Map.png","/map-media/2efd07837ffa9b11e337.png":"Item_350021_Map.png","/map-media/550a279d7d535550d59f.png":"Item_350016_Map.png","/map-media/61efb0eecabc5ad3274c.png":"Item_350011_Map.png","/map-media/391c86edfd5932656257.png":"Item_100688_Map.png","/map-media/f02cd85c7c5d51e4db1a.png":"Item_100689_Map.png","/map-media/60b39833f31cd45e1217.png":"Item_100690_Map.png","/map-media/b9fbfa4a5efa4cc3a4d3.png":"Item_100691_Map.png","/map-media/8095b3380fb3f3d1fd51.png":"Item_100693_Map.png","/map-media/f0870e681bf95eb4309a.png":"Item_100694_Map.png","/map-media/3322c119e4f1e5dbcc04.png":"Item_100695_Map.png","/map-media/140320eb0ce722cb5d78.png":"Item_100696_Map.png","/map-media/6b8d8d78ff9020795a38.png":"Item_101055.png","/map-media/8b3056c465012f75b4f6.png":"Item_100674_Map.png","/map-media/1cfc7bb11259ca75d7af.png":"Item_100608_Map.png","/map-media/9a43e4796c43ee61cb2a.png":"Item_100662.png","/map-media/3f83507bff3a2c7a24ab.png":"Item_101056.png","/map-media/0a2915dc7da7cd727a3c.png":"Item_100854.png","/map-media/e8cbe5b7ebd39a76c514.png":"Item_100670_Map.png","/map-media/69087b2c25f54b48fd1a.png":"Item_107228.png","/map-media/4f367c1d0c0667a1dee3.png":"Item_310049.png","/map-media/9f0a30d1ede0af705222.png":"Item_310089.png","/map-media/e06e7a017fac0747e94a.png":"Item_320075.png","/map-media/f46f88b3ec85825ea814.png":"Item_108239.png","/map-media/accca00d5e9d101b1b4b.png":"Item_320031.png","/map-media/c667feb59fa80821f1b3.png":"Item_320031.png","/map-media/6c500e8e3a0bb82104e1.png":"Item_320031.png","/map-media/402648cacd938f14721f.png":"Item_320031.png","/map-media/77a5d7ea224a44190cb4.png":"Item_320031.png","/map-media/f07a12106b95af256e5b.png":"Item_320031.png","/map-media/ca684e3012dd6b5baed5.png":"Item_100983.png","/map-media/439ddcb730c992ee47cc.png":"Item_85.png","/map-media/705faa1eb8bbf7b7ee58.png":"PetAvatar_3775.png","/map-media/2d453e8e90b2405f7d23.png":"PetAvatar_3591_Map.png","/map-media/e74d184c6fccbbd720ad.png":"PetAvatar_3236.png","/map-media/912e622ff4e53447b850.png":"PetAvatar_3616_Map.png","/map-media/b613a861ef183f77306d.png":"PetAvatar_3663.png","/map-media/b644ec380f7762d1d267.png":"PetAvatar_3767.png","/map-media/437adac666cd34924fff.png":"PetAvatar_3760_Map.png","/map-media/574c207276316b75bcd4.png":"PetAvatar_3771.png","/map-media/0b6575d36e2f20c2dabb.png":"PetAvatar_3773.png","/map-media/52b5c6898f54d6759394.png":"PetAvatar_3706_Map.png","/map-media/6cb38bc81fbc7be0a7f0.png":"PetAvatar_3542.png","/map-media/b2f24497e5df9f4f43a9.png":"PetAvatar_3589.png","/map-media/2a6c75cda71ff56856d7.png":"PetAvatar_3759.png","/map-media/9f199ee0536a9b3c1e13.png":"PetAvatar_3319_Map.png","/map-media/0ca904b019dc9f7ad389.png":"PetAvatar_3171_Map.png","/map-media/b832bdcb5954ef8295a7.png":"PetAvatar_3150_Map.png","/map-media/56e444a3332142ae3ccf.png":"PetAvatar_3566_Map.png","/map-media/966db2606b2fb162e00e.png":"PetAvatar_3102_Map.png","/map-media/2ad31514e8f7878365f4.png":"PetAvatar_3448_Map.png","/map-media/b28b50e576b1d2ff0d73.png":"Item_108252_Map.png","/map-media/3d152918eb8e683355fa.png":"PetAvatar_3747_Map.png","/map-media/d5e192b86834c0b0e30b.png":"PetAvatar_3748_Map.png","/map-media/babd2f11e0345900a761.png":"Item_108240_Map.png","/map-media/f049fd3ccf2f2514bd40.png":"PetAvatar_3228_Map.png","/map-media/65d7bab47f81ac630519.png":"PetAvatar_3229_Map.png","/map-media/fd87867a8a0e2e7e8355.png":"Item_20000023_Map.png","/map-media/3cb1b4623c1c3e89407f.png":"Item_150525_Map.png","/map-media/b49f856c77d60d17db48.png":"Item_20000024_Map.png","/map-media/83d4acfeb0f2e0209e83.png":"Item_150527_Map.png","/map-media/01afa9092e6eab7ea297.png":"Item_20000025_Map.png","/map-media/46b4c5d18e17bb9dbd72.png":"Item_150528_Map.png","/map-media/5ace3b86e331d9157bab.png":"MapTypeChest_Light.png","/map-media/9c0fc10d565f184bf685.png":"MapTypeChest_Dark.png","/map-media/bf121d119c31181e1652.png":"MapTypeChest_Grass.png","/map-media/e05abc60a7b3535209f8.png":"MapTypeChest_Fire.png","/map-media/d98994aa6a3cab2876d4.png":"MapTypeChest_Water.png","/map-media/305544dd51ae5c04d570.png":"MapTypeChest_Wing.png","/map-media/b84374e4b7656cfdfb2f.png":"MapTypeChest_Bug.png","/map-media/8518659864be19fd0aff.png":"MapTypeChest_Ice.png","/map-media/8d483054aef5e4a466c4.png":"MapTypeChest_Normal.png","/map-media/5ee5ed864cbe0fcb66b5.png":"MapTypeChest_Ground.png","/map-media/4ec13c25f35df1886378.png":"MapTypeChest_Dragon.png","/map-media/54b85c844269b6654827.png":"MapTypeChest_Electric.png","/map-media/bbd697bb9c89bdf77d42.png":"MapTypeChest_Poison.png","/map-media/fc156c43f70bac04e383.png":"MapTypeChest_Martial.png","/map-media/55116c57c15466a63cbf.png":"MapTypeChest_Cute.png","/map-media/6d6995ec807fbd9075d2.png":"MapTypeChest_Ghost.png","/map-media/b3bac103ff69d17859e0.png":"MapTypeChest_Mechanical.png","/map-media/ec1eaca08c086a41a782.png":"MapTypeChest_Fantasy.png","/map-media/d794534a677508d08633.png":"PetAvatar_4072.png","/map-media/76b80cd4cdf5689782c3.png":"MapMarkerPortrait_4074_1.png","/map-media/a6d9d9688357bb0d6050.png":"PetAvatar_4021.png","/map-media/d26f0e905728a414070d.png":"PetAvatar_4022.png","/map-media/57a82017d4ea542fde8c.png":"MapMarkerPortrait_4020.png","/map-media/0016b334d4a109e811a1.png":"PetAvatar_4085.png","/map-media/c62153769e3b47b31dd5.png":"MapMarkerPortrait_4090.png","/map-media/e1e4df96ec9dbae025aa.png":"MapMarkerPortrait_4088.png","/map-media/ed893b1a1bc5d65704e2.png":"MapMarkerPortrait_4086.png","/map-media/efacc5b81269fdb89b3a.png":"MapMarkerPortrait_4079.png","/map-media/b50d33988703f926e29e.png":"PetAvatar_4019.png","/map-media/f399bf3abe1d8d24d3c6.png":"MapMarkerPortrait_4089.png","/map-media/50079b619b0d50a1dd4a.png":"PetAvatar_4064.png","/map-media/0774524f8810f48777f5.png":"MapMarkerPortrait_4011.png","/map-media/5105a1b28c75eb51ad87.png":"MapMarkerPortrait_4084.png","/map-media/662b17548009db856d41.png":"MapMarkerPortrait_4087.png","/map-media/a053636e27cf9785bee1.png":"PetAvatar_4083.png","/map-media/8ce584b64cc8a8aa18fb.png":"MapNpcPortrait_10186.png","/map-media/0e3e43c93299b345bf8f.png":"MapNpcPortrait_10188.png","/map-media/ea0fda499461c38f3359.png":"MapNpcPortrait_10133.png","/map-media/4d7e0efc720a391cc531.png":"MapNpcPortrait_10033.png","/map-media/a40364f6b1c9bfbda9db.png":"MapNpcPortrait_10161.png","/map-media/fcdb34f508681425b38f.png":"MapNpcPortrait_10144.png","/map-media/17b631bec8811884d14b.png":"MapNpcPortrait_10145.png","/map-media/9fc26709d22458d191b0.png":"MapNpcPortrait_10115.png","/map-media/389df4b59fc169af9b14.png":"MapNpcPortrait_10102.png","/map-media/7eb55ee6795e655744d4.png":"MapNpcPortrait_10111.png","/map-media/2f0dabb73c6368aa9e01.png":"MapNpcPortrait_10036.png","/map-media/8283d99cbbeb31cf4eaa.png":"MapNpcPortrait_10038.png","/map-media/01c14eace2851b723dfe.png":"MapNpcPortrait_10070.png","/map-media/678fcf4687ea25150c3c.png":"MapNpcPortrait_10032.png","/map-media/fc913f6c018af4b49610.png":"MapNpcPortrait_10155.png","/map-media/38a6ce11fc3f131dd378.png":"MapNpcPortrait_10167.png","/map-media/382a76eed3272ea1a731.png":"MapNpcPortrait_10183.png","/map-media/3ec46c656788a5a87688.png":"MapNpcPortrait_10179.png","/map-media/afecf3dead7d903f34a3.png":"MapNpcPortrait_10117.png","/map-media/612f66c862427bd7ef97.png":"MapNpcPortrait_10138.png","/map-media/9192524851b13a8808ed.png":"MapNpcPortrait_10125.png","/map-media/4f419e2001dbb32645bf.png":"MapNpcPortrait_10087.png","/map-media/1d2b0b778ede31f0eae4.png":"MapNpcPortrait_10208.png","/map-media/471f3874792d511e4040.png":"MapNpcPortrait_10129.png","/map-media/7657fdb6211174d1dea4.png":"MapNpcPortrait_10189.png","/map-media/17de04874f016444da2d.png":"MapNpcPortrait_10190.png","/map-media/f76b10d482430cff0752.png":"MapNpcPortrait_10103.png","/map-media/0e447c04cce748766fc4.png":"MapNpcPortrait_10106.png","/map-media/10c29b0d2f2787001111.png":"MapNpcPortrait_10119.png","/map-media/bdca93ad0941b9c8be96.png":"MapNpcPortrait_10100.png","/map-media/82566c3db2d73ec204fd.png":"MapNpcPortrait_10184.png","/map-media/1ba034ffdfa48109ef8b.png":"MapNpcPortrait_10177.png","/map-media/62a54752b2897f78c3d5.png":"MapNpcPortrait_10205.png","/map-media/1408e423d4fad39ff444.png":"MapNpcPortrait_10206.png","/map-media/2f56343d8c90da9091bb.png":"MapNpcPortrait_10209.png","/map-media/5123a8a8b769d8f411c5.png":"MapNpcPortrait_10207.png","/map-media/75c54b80cd23aed8af3e.png":"MapNpcPortrait_10210.png","/map-media/a4bfc3352acdfaa581b7.png":"MapNpcPortrait_10120.png","/map-media/b736389b32b184d9323f.png":"MapNpcPortrait_10031.png","/map-media/af370e0fe4c0eb81a558.png":"MapNpcPortrait_10182.png","/map-media/af94200d5a43ae97b510.png":"MapNpcPortrait_10041.png","/map-media/6f0655834e9f2e5196f4.png":"MapNpcPortrait_10108.png","/map-media/e8d3a4a6e332f1be7130.png":"MapNpcPortrait_10107.png","/map-media/370998f7f75d4131b5be.png":"MapNpcPortrait_10104.png","/map-media/33955e165b226bc467f9.png":"MapNpcPortrait_10109.png","/map-media/5e9162bc2b8272091e0c.png":"MapNpcPortrait_10112.png","/map-media/cc86b3e0e2f8d5b6b3f6.png":"MapNpcPortrait_10097.png","/map-media/db02d24d6454f8da109c.png":"MapNpcPortrait_10099.png","/map-media/492cce2061893f7bb2a1.png":"MapNpcPortrait_10098.png","/map-media/c2b6ac35659e09b67e88.png":"MapNpcPortrait_10116.png","/map-media/77edf69dc46ac1a08b07.png":"MapNpcPortrait_10004.png","/map-media/72860efa83cf8e5b6e9e.png":"MapNpcPortrait_10187.png","/map-media/0eb992aa6a9b00fa47c8.png":"MapNpcPortrait_10137.png","/map-media/ca5ddb57652f25c3c572.png":"MapNpcPortrait_10086.png","/map-media/e83dda28881f9b802d08.png":"MapNpcPortrait_10048.png","/map-media/7b7da735087584401f3a.png":"MapNpcPortrait_10049.png","/map-media/2e1e7f6311083f8e4ed6.png":"MapNpcPortrait_10046.png","/map-media/bbb3101e3b0af1538d43.png":"MapNpcPortrait_10047.png","/map-media/832d184b4137de245d2a.png":"MapNpcPortrait_10176.png","/map-media/a1ae5e9ec3174b69efb5.png":"MapNpcPortrait_10169.png","/map-media/4f2a31d3f0bb146f8952.png":"MapNpcPortrait_10037.png","/map-media/bd6534185605daf5d8d4.png":"MapNpcPortrait_10027.png","/map-media/94d358b4fc6619c9766b.png":"MapNpcPortrait_10029.png","/map-media/ecdbe905cfaf6cf7567d.png":"MapNpcPortrait_10105.png","/map-media/d8b2af66285be4832c46.png":"MapNpcPortrait_generic_challenge.png","/map-media/06a9f98484d974da9236.png":"MapNpcPortrait_10151.png","/map-media/ae3835a97b5e42262a20.png":"MapNpcPortrait_10192.png","/map-media/025fc45a47b70054b6be.png":"MapNpcPortrait_10067.png","/map-media/b5e593c8f81c8511fa3f.png":"MapNpcPortrait_10040.png","/map-media/578dc6a9440bb35bf1e9.png":"MapNpcPortrait_10222.png","/map-media/04cb7a44e177d5bbb77a.png":"MapNpcPortrait_10181.png","/map-media/2d05692c3dc057921dfd.png":"MapNpcPortrait_10148.png","/map-media/23e217521e58bc9e9b8c.png":"MapNpcPortrait_10059.png","/map-media/f1b164d6e1d029620118.png":"MapNpcPortrait_3347.png","/map-media/e8611d39f2bb1fa87d14.png":"MapMarkerPortrait_3394.png","/map-media/d25d4383c2ad95fd835d.png":"PetAvatar_3182.png","/map-media/27ac89d1d36cff79a1fc.png":"PetAvatar_3232.png","/map-media/2141e1ceaeb5cb79f2a0.png":"MapNpcPortrait_10113.png","/map-media/968660d5be15ee185de5.png":"MapNpcPortrait_10118.png","/map-media/13076f64cbf2b5cbc7e9.png":"MapNpcPortrait_10101.png","/map-media/9325a4ca8e4337475402.png":"MapNpcPortrait_10114.png","/map-media/5b40044ec8f67f372976.png":"MapNpcPortrait_10146.png","/map-media/557a09a6900e86a9e5a2.png":"MapIcon_MasterShop.png","/map-media/85c13492d39a7db54e5c.png":"MapNpcPortrait_PEO_00214.png","/map-media/ac9d56c691cf0152406a.png":"MapNpcPortrait_PEO_00215.png","/map-media/ee39e976708aadce64de.png":"MapNpcPortrait_PEO_00216.png","/map-media/cd89ed8c67e49fda6f88.png":"MapNpcPortrait_PEO_06601.png","/map-media/3d2f58bcb24b4fb17c07.png":"MapNpcPortrait_PEO_06602.png","/map-media/eb3babde10dd75562111.png":"MapNpcPortrait_PEO_00205.png","/map-media/ed5b5caff1e1d98ad2f0.png":"MapNpcPortrait_PEO_02303.png","/map-media/14f1f301d5dc10fde855.png":"MapNpcPortrait_10148.png","/map-media/f7160cf3b1c679f886b9.png":"MapNpcPortrait_PEO_00106.png","/map-media/43d433b827aaabc09f84.png":"MapNpcPortrait_05302.png","/map-media/6ba73a74836ce2ff5721.png":"MapNpcPortrait_PEO_06105.png","/map-media/3852da8a5993ea58bf1b.png":"MapNpcPortrait_PEO_00314.png","/map-media/333f1577fc7ef6bf2455.png":"MapNpcPortrait_PEO_00315.png","/map-media/e025a459b7f92f571f96.png":"MapNpcPortrait_PEO_00204.png","/map-media/67f04bbda74ba2906541.png":"PetAvatar_4101.png","/map-media/b412fe9c9b8a256cca1a.png":"PetAvatar_4102.png","/map-media/2b81bf132c608fa72e1c.png":"PetAvatar_4104.png","/map-media/ffbbaecf98ac25438740.png":"MapIcon_SeasonLobby1.png","/map-media/fd127ad10e48042b288b.png":"MapIcon_SeasonLobby2.png","/map-media/4a2bdb7bbe531cfd6d67.png":"MapIcon_SeasonLobby3.png","/map-media/tiles-c91ebf8e8d874eae1ba0/01.png":"Map_Academy_Surface_Tile01.png","/map-media/tiles-c91ebf8e8d874eae1ba0/02.png":"Map_Academy_Surface_Tile02.png","/map-media/tiles-c91ebf8e8d874eae1ba0/03.png":"Map_Academy_Surface_Tile03.png","/map-media/tiles-c91ebf8e8d874eae1ba0/04.png":"Map_Academy_Surface_Tile04.png","/map-media/tiles-c91ebf8e8d874eae1ba0/05.png":"Map_Academy_Surface_Tile05.png","/map-media/tiles-c91ebf8e8d874eae1ba0/06.png":"Map_Academy_Surface_Tile06.png","/map-media/tiles-c91ebf8e8d874eae1ba0/07.png":"Map_Academy_Surface_Tile07.png","/map-media/tiles-c91ebf8e8d874eae1ba0/08.png":"Map_Academy_Surface_Tile08.png","/map-media/tiles-c91ebf8e8d874eae1ba0/09.png":"Map_Academy_Surface_Tile09.png","/map-media/tiles-c91ebf8e8d874eae1ba0/10.png":"Map_Academy_Surface_Tile10.png","/map-media/tiles-c91ebf8e8d874eae1ba0/11.png":"Map_Academy_Surface_Tile11.png","/map-media/tiles-c91ebf8e8d874eae1ba0/12.png":"Map_Academy_Surface_Tile12.png","/map-media/tiles-c91ebf8e8d874eae1ba0/13.png":"Map_Academy_Surface_Tile13.png","/map-media/tiles-c91ebf8e8d874eae1ba0/14.png":"Map_Academy_Surface_Tile14.png","/map-media/tiles-c91ebf8e8d874eae1ba0/15.png":"Map_Academy_Surface_Tile15.png","/map-media/tiles-c91ebf8e8d874eae1ba0/16.png":"Map_Academy_Surface_Tile16.png","/map-media/tiles-9382aa703ef339597cd0/01.png":"Map_Academy_Unexplored_Tile01.png","/map-media/tiles-9382aa703ef339597cd0/02.png":"Map_Academy_Unexplored_Tile02.png","/map-media/tiles-9382aa703ef339597cd0/03.png":"Map_Academy_Unexplored_Tile03.png","/map-media/tiles-9382aa703ef339597cd0/04.png":"Map_Academy_Unexplored_Tile04.png","/map-media/tiles-9382aa703ef339597cd0/05.png":"Map_Academy_Unexplored_Tile05.png","/map-media/tiles-9382aa703ef339597cd0/06.png":"Map_Academy_Unexplored_Tile06.png","/map-media/tiles-9382aa703ef339597cd0/07.png":"Map_Academy_Unexplored_Tile07.png","/map-media/tiles-9382aa703ef339597cd0/08.png":"Map_Academy_Unexplored_Tile08.png","/map-media/tiles-9382aa703ef339597cd0/09.png":"Map_Academy_Unexplored_Tile09.png","/map-media/tiles-9382aa703ef339597cd0/10.png":"Map_Academy_Unexplored_Tile10.png","/map-media/tiles-9382aa703ef339597cd0/11.png":"Map_Academy_Unexplored_Tile11.png","/map-media/tiles-9382aa703ef339597cd0/12.png":"Map_Academy_Unexplored_Tile12.png","/map-media/tiles-9382aa703ef339597cd0/13.png":"Map_Academy_Unexplored_Tile13.png","/map-media/tiles-9382aa703ef339597cd0/14.png":"Map_Academy_Unexplored_Tile14.png","/map-media/tiles-9382aa703ef339597cd0/15.png":"Map_Academy_Unexplored_Tile15.png","/map-media/tiles-9382aa703ef339597cd0/16.png":"Map_Academy_Unexplored_Tile16.png","/map-media/tiles-956d752d74a8ebd9b8a8/01.png":"Map_Academy_Underground_Tile01.png","/map-media/tiles-956d752d74a8ebd9b8a8/02.png":"Map_Academy_Underground_Tile02.png","/map-media/tiles-956d752d74a8ebd9b8a8/03.png":"Map_Academy_Underground_Tile03.png","/map-media/tiles-956d752d74a8ebd9b8a8/04.png":"Map_Academy_Underground_Tile04.png","/map-media/tiles-956d752d74a8ebd9b8a8/05.png":"Map_Academy_Underground_Tile05.png","/map-media/tiles-956d752d74a8ebd9b8a8/06.png":"Map_Academy_Underground_Tile06.png","/map-media/tiles-956d752d74a8ebd9b8a8/07.png":"Map_Academy_Underground_Tile07.png","/map-media/tiles-956d752d74a8ebd9b8a8/08.png":"Map_Academy_Underground_Tile08.png","/map-media/tiles-956d752d74a8ebd9b8a8/09.png":"Map_Academy_Underground_Tile09.png","/map-media/tiles-956d752d74a8ebd9b8a8/10.png":"Map_Academy_Underground_Tile10.png","/map-media/tiles-956d752d74a8ebd9b8a8/11.png":"Map_Academy_Underground_Tile11.png","/map-media/tiles-956d752d74a8ebd9b8a8/12.png":"Map_Academy_Underground_Tile12.png","/map-media/tiles-956d752d74a8ebd9b8a8/13.png":"Map_Academy_Underground_Tile13.png","/map-media/tiles-956d752d74a8ebd9b8a8/14.png":"Map_Academy_Underground_Tile14.png","/map-media/tiles-956d752d74a8ebd9b8a8/15.png":"Map_Academy_Underground_Tile15.png","/map-media/tiles-956d752d74a8ebd9b8a8/16.png":"Map_Academy_Underground_Tile16.png","/map-media/tiles-e78695d3b45bf4398d96/01.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/02.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/03.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/04.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/05.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/06.png":"Map_Academy_Surface_Tile06_HD.png","/map-media/tiles-e78695d3b45bf4398d96/07.png":"Map_Academy_Surface_Tile07_HD.png","/map-media/tiles-e78695d3b45bf4398d96/08.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/09.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/10.png":"Map_Academy_Surface_Tile10_HD.png","/map-media/tiles-e78695d3b45bf4398d96/11.png":"Map_Academy_Surface_Tile11_HD.png","/map-media/tiles-e78695d3b45bf4398d96/12.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/13.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-e78695d3b45bf4398d96/14.png":"Map_Academy_Surface_Tile14_HD.png","/map-media/tiles-e78695d3b45bf4398d96/15.png":"Map_Academy_Surface_Tile15_HD.png","/map-media/tiles-e78695d3b45bf4398d96/16.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/01.png":"Map_Academy_Unexplored_Tile01_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/02.png":"Map_Academy_Unexplored_Tile02_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/03.png":"Map_Academy_Unexplored_Tile03_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/04.png":"Map_Academy_Unexplored_Tile04_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/05.png":"Map_Academy_Unexplored_Tile05_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/06.png":"Map_Academy_Unexplored_Tile06_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/07.png":"Map_Academy_Unexplored_Tile07_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/08.png":"Map_Academy_Unexplored_Tile08_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/09.png":"Map_Academy_Unexplored_Tile09_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/10.png":"Map_Academy_Unexplored_Tile10_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/11.png":"Map_Academy_Unexplored_Tile11_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/12.png":"Map_Academy_Unexplored_Tile12_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/13.png":"Map_Academy_Unexplored_Tile13_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/14.png":"Map_Academy_Unexplored_Tile14_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/15.png":"Map_Academy_Unexplored_Tile15_HD.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/16.png":"Map_Academy_Unexplored_Tile16_HD.png","/map-media/tiles-fc182847a7daff3aeccb/01.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/02.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/03.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/04.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/05.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/06.png":"Map_Academy_Underground_Tile06_HD.png","/map-media/tiles-fc182847a7daff3aeccb/07.png":"Map_Academy_Underground_Tile07_HD.png","/map-media/tiles-fc182847a7daff3aeccb/08.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/09.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/10.png":"Map_Academy_Underground_Tile10_HD.png","/map-media/tiles-fc182847a7daff3aeccb/11.png":"Map_Academy_Underground_Tile11_HD.png","/map-media/tiles-fc182847a7daff3aeccb/12.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/13.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/tiles-fc182847a7daff3aeccb/14.png":"Map_Academy_Underground_Tile14_HD.png","/map-media/tiles-fc182847a7daff3aeccb/15.png":"Map_Academy_Underground_Tile15_HD.png","/map-media/tiles-fc182847a7daff3aeccb/16.png":"Map_Mainland_Surface_Tile04_HD.png","/map-media/bd3e1d29024ef5802494.png":"MapIcon_Airship.png","/map-media/26319d118832314c50cd.png":"MapIcon_Temple.png","/map-media/f67e913dce402a7730d6.png":"MapNpcPortrait_01208.png","/map-media/956fafd065c98f78df20.png":"Item_100727_Map.png","/map-media/901403b8459735c0ecde.png":"Item_100729_Map.png","/map-media/ca96e300f158a1a13c10.png":"Item_100730.png","/map-media/a34e03e196dc3abe5d5b.png":"Item_100731.png","/map-media/82069e986f34ae8c73d7.png":"Item_720017.png","/map-media/89573b9f9edf0b6b59d3.png":"Item_720017.png","/map-media/ba7fa1b8d823798deaa2.png":"Item_720019.png","/map-media/6ce2641f17df1728439b.png":"Item_720019.png","/map-media/54d02c83d4b7d8fed6b7.png":"Item_720006.png","/map-media/8f465047c8acd4cafda3.png":"Item_720006.png","/map-media/171d8967f242cdb66888.png":"Item_720021.png","/map-media/eaaa3b1608ff0cf08392.png":"Item_720021.png","/map-media/f0b608ec3fdc8db2fe90.png":"Item_720023.png","/map-media/5928388d6cdaa9260048.png":"Item_720023.png","/map-media/277ba5329f1213d95549.png":"Item_310058.png","/map-media/6da4f01f4346f5897a60.png":"MapIcon_AcademySchedule.png","/map-media/2f2d60e1bfd89b0373af.png":"MapNpcPortrait_01709.png","/map-media/e6fd536d1a64b6a5a301.png":"MapNpcPortrait_01610.png","/map-media/f657f550a6d72db662c5.png":"MapNpcPortrait_01411.png","/map-media/aaf12989606c6dc7593c.png":"MapIcon_MarkerCircle.png","/map-media/3361522b305b61200f90.png":"MapIcon_MarkerCircleSelected.png","/map-media/d45629f095c70ede0315.png":"MapIcon_FocusArrow.png","/map-media/ba1c3c70b1ff059cab60.png":"MapIcon_FocusBracket.png"},"assetUrls":{"/map-media/tiles-08e9506c2555bae050be/01.png":"https://patchwiki.biligame.com/images/nrc/5/57/61yxsiquytdzotpcpvomienw35et5v0.png","/map-media/tiles-08e9506c2555bae050be/02.png":"https://patchwiki.biligame.com/images/nrc/a/a7/1vev9yix9e9yse8qmixkr93dmyrsq0o.png","/map-media/tiles-08e9506c2555bae050be/03.png":"https://patchwiki.biligame.com/images/nrc/2/25/15y3m34ss6ivfw8e48106jo3fmtsrpo.png","/map-media/tiles-08e9506c2555bae050be/04.png":"https://patchwiki.biligame.com/images/nrc/f/f6/9tg2qs60tmc89iz3fdlbxv2bativt4a.png","/map-media/tiles-08e9506c2555bae050be/05.png":"https://patchwiki.biligame.com/images/nrc/6/63/gkohj0u7xuprv42yp5qjkz9rmg529ky.png","/map-media/tiles-08e9506c2555bae050be/06.png":"https://patchwiki.biligame.com/images/nrc/0/03/lamrw5xs7dkzb8jacy8zi57ibwtjf7c.png","/map-media/tiles-08e9506c2555bae050be/07.png":"https://patchwiki.biligame.com/images/nrc/e/ef/no6xv1s2q62fwetkj6agrgy6c542lru.png","/map-media/tiles-08e9506c2555bae050be/08.png":"https://patchwiki.biligame.com/images/nrc/b/b4/100rcbyq4b63jk8j85jaia2lwel1ozw.png","/map-media/tiles-08e9506c2555bae050be/09.png":"https://patchwiki.biligame.com/images/nrc/e/ec/d4z3hglg4hv2n98lg80pm5w48rqtdi6.png","/map-media/tiles-08e9506c2555bae050be/10.png":"https://patchwiki.biligame.com/images/nrc/c/ca/7rse2p4e1eao6upq9pfb3slym0i16or.png","/map-media/tiles-08e9506c2555bae050be/11.png":"https://patchwiki.biligame.com/images/nrc/5/51/j098b9uxm09v8vsu9f8sraxzp9b2g24.png","/map-media/tiles-08e9506c2555bae050be/12.png":"https://patchwiki.biligame.com/images/nrc/e/ea/e67p8ecrb5attopoernkus1tj6wme8o.png","/map-media/tiles-08e9506c2555bae050be/13.png":"https://patchwiki.biligame.com/images/nrc/0/0a/9wzyhvfgowx1r4benxwyjdikkl5ux84.png","/map-media/tiles-08e9506c2555bae050be/14.png":"https://patchwiki.biligame.com/images/nrc/6/67/jedkxo4eyqx4q9f655j7rylnmnuvyr7.png","/map-media/tiles-08e9506c2555bae050be/15.png":"https://patchwiki.biligame.com/images/nrc/d/dc/3c279nvqfotlb6q6x281b4q5p410y3n.png","/map-media/tiles-08e9506c2555bae050be/16.png":"https://patchwiki.biligame.com/images/nrc/8/8c/7hpcy4yjdjy3bpz2405v91svt491ytj.png","/map-media/tiles-125d870bfcf691a2599f/01.png":"https://patchwiki.biligame.com/images/nrc/f/f9/id8wn65qg64sutkxvgkvqk67593frnm.png","/map-media/tiles-125d870bfcf691a2599f/02.png":"https://patchwiki.biligame.com/images/nrc/b/b5/0qgkpou8hdks27sb2qmcwsr7k6o97l6.png","/map-media/tiles-125d870bfcf691a2599f/03.png":"https://patchwiki.biligame.com/images/nrc/3/36/i19n0gnxw0wwaaskuex13zqf2qbrwpe.png","/map-media/tiles-125d870bfcf691a2599f/04.png":"https://patchwiki.biligame.com/images/nrc/1/10/bui2b5kkz2fcrlacip1khcrxzrjw8ew.png","/map-media/tiles-125d870bfcf691a2599f/05.png":"https://patchwiki.biligame.com/images/nrc/4/4c/6kc6dcsm2etwmer4fcgx5lidzhsw5je.png","/map-media/tiles-125d870bfcf691a2599f/06.png":"https://patchwiki.biligame.com/images/nrc/f/f0/gjph89z77lah1xf3nbe5qhj24av0znc.png","/map-media/tiles-125d870bfcf691a2599f/07.png":"https://patchwiki.biligame.com/images/nrc/4/45/25tz5yylnpegvu2wcclqdrmo9jqx48u.png","/map-media/tiles-125d870bfcf691a2599f/08.png":"https://patchwiki.biligame.com/images/nrc/2/27/00ubf1zkcbmt9397bnin1gppu59hw7x.png","/map-media/tiles-125d870bfcf691a2599f/09.png":"https://patchwiki.biligame.com/images/nrc/0/02/pg9geecmiz4steni04skmzyhc2ycb9b.png","/map-media/tiles-125d870bfcf691a2599f/10.png":"https://patchwiki.biligame.com/images/nrc/4/41/rokvqhkijcv0wog1u2m9e9tyrsieak1.png","/map-media/tiles-125d870bfcf691a2599f/11.png":"https://patchwiki.biligame.com/images/nrc/f/fa/e14omjer1gl4kmxpcc7j552ltd1yzij.png","/map-media/tiles-125d870bfcf691a2599f/12.png":"https://patchwiki.biligame.com/images/nrc/e/e2/foq9nex50tm1nw5289nggh0ci1kenr5.png","/map-media/tiles-125d870bfcf691a2599f/13.png":"https://patchwiki.biligame.com/images/nrc/2/28/8xmypxhfhsbiqgnhrwhj62efoexb80i.png","/map-media/tiles-125d870bfcf691a2599f/14.png":"https://patchwiki.biligame.com/images/nrc/d/d2/qy5l72tbjmceljepy09o7ixcb7d41xj.png","/map-media/tiles-125d870bfcf691a2599f/15.png":"https://patchwiki.biligame.com/images/nrc/a/a4/ewemu815qqz3b2bk6hxs8a2muwrt1so.png","/map-media/tiles-125d870bfcf691a2599f/16.png":"https://patchwiki.biligame.com/images/nrc/1/1a/3bnaowxmqb03h26e31kuwz2k6bs2jqv.png","/map-media/tiles-880f4ac73b07e89f13d4/01.png":"https://patchwiki.biligame.com/images/nrc/9/9e/k4yciot7msuwg9f5o1ncuifyvl75xy4.png","/map-media/tiles-880f4ac73b07e89f13d4/02.png":"https://patchwiki.biligame.com/images/nrc/4/4e/i56iw2he8plusbs4a9s44yyv9lt31dq.png","/map-media/tiles-880f4ac73b07e89f13d4/03.png":"https://patchwiki.biligame.com/images/nrc/c/cf/aqi5v6c1x0ef9r0mjf0zfeclxwqtut0.png","/map-media/tiles-880f4ac73b07e89f13d4/04.png":"https://patchwiki.biligame.com/images/nrc/3/3e/kg2nbzy8qf3ofrytlay76qrpa080ps8.png","/map-media/tiles-880f4ac73b07e89f13d4/05.png":"https://patchwiki.biligame.com/images/nrc/6/67/g6z13wnksimt9b8j3ptdpzk8neoosti.png","/map-media/tiles-880f4ac73b07e89f13d4/06.png":"https://patchwiki.biligame.com/images/nrc/a/a8/d7ltdhdb08qa5rrecfxgyxm4gbcnel9.png","/map-media/tiles-880f4ac73b07e89f13d4/07.png":"https://patchwiki.biligame.com/images/nrc/6/62/h7cxhnxcwh1199u90xiex9baeudfgx7.png","/map-media/tiles-880f4ac73b07e89f13d4/08.png":"https://patchwiki.biligame.com/images/nrc/0/0a/jpqrh7fe2300o09eyl2i2g7yn64ntar.png","/map-media/tiles-880f4ac73b07e89f13d4/09.png":"https://patchwiki.biligame.com/images/nrc/4/4d/b69m63d5zh4v22351uh8ajavpgrha28.png","/map-media/tiles-880f4ac73b07e89f13d4/10.png":"https://patchwiki.biligame.com/images/nrc/2/2d/eyfnwh105vhszhlr6rg3p1st7br5qn5.png","/map-media/tiles-880f4ac73b07e89f13d4/11.png":"https://patchwiki.biligame.com/images/nrc/1/12/lcyal3q047ifws1leb1wsa7rormisgp.png","/map-media/tiles-880f4ac73b07e89f13d4/12.png":"https://patchwiki.biligame.com/images/nrc/f/f5/oez90qsyjfxatga2qhdel72b1z6x5bo.png","/map-media/tiles-880f4ac73b07e89f13d4/13.png":"https://patchwiki.biligame.com/images/nrc/b/b2/pxnywncqeaepnpbpnasek98w0o92cba.png","/map-media/tiles-880f4ac73b07e89f13d4/14.png":"https://patchwiki.biligame.com/images/nrc/f/fc/entz8ivq2whxudqbmapczx7igifcdm7.png","/map-media/tiles-880f4ac73b07e89f13d4/15.png":"https://patchwiki.biligame.com/images/nrc/3/3e/o4whvn2ym025s69eczudc5lpeybsr2d.png","/map-media/tiles-880f4ac73b07e89f13d4/16.png":"https://patchwiki.biligame.com/images/nrc/6/6b/9d0pevuye7j1v1b5256sd4tmrofwfzn.png","/map-media/tiles-54c7170546b6109bab59/01.png":"https://patchwiki.biligame.com/images/nrc/2/28/gf5xqwkoqa5l1n7itluijih0mh418d2.png","/map-media/tiles-54c7170546b6109bab59/02.png":"https://patchwiki.biligame.com/images/nrc/b/b7/iad462bo2b8ctq32ck9ztqiynd6wg2h.png","/map-media/tiles-54c7170546b6109bab59/03.png":"https://patchwiki.biligame.com/images/nrc/e/e8/o27tm2rt32sxzlepx0cf1rp3tw0t1ah.png","/map-media/tiles-54c7170546b6109bab59/04.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-54c7170546b6109bab59/05.png":"https://patchwiki.biligame.com/images/nrc/a/a0/5kfrc2agalr6qoczl0r9c7b2229xf5y.png","/map-media/tiles-54c7170546b6109bab59/06.png":"https://patchwiki.biligame.com/images/nrc/e/ee/7a4gljvcnao2kfbklqz1xck202equ1c.png","/map-media/tiles-54c7170546b6109bab59/07.png":"https://patchwiki.biligame.com/images/nrc/4/44/tgx6e235534apru07bggsrpasu73orr.png","/map-media/tiles-54c7170546b6109bab59/08.png":"https://patchwiki.biligame.com/images/nrc/c/cd/p884rbc1mndpw3lt5lg5edzvznxc4z8.png","/map-media/tiles-54c7170546b6109bab59/09.png":"https://patchwiki.biligame.com/images/nrc/9/9d/i974yio9pr1o8fh4j3b5758vq88khho.png","/map-media/tiles-54c7170546b6109bab59/10.png":"https://patchwiki.biligame.com/images/nrc/5/5a/ahglympvudn99o3n6lgozrm84iit0dt.png","/map-media/tiles-54c7170546b6109bab59/11.png":"https://patchwiki.biligame.com/images/nrc/a/ad/kh9rv9p3fm29qygxwrimzwcquw9176p.png","/map-media/tiles-54c7170546b6109bab59/12.png":"https://patchwiki.biligame.com/images/nrc/8/88/o5qu087csdf9varyx4yaipelg2wore7.png","/map-media/tiles-54c7170546b6109bab59/13.png":"https://patchwiki.biligame.com/images/nrc/0/06/3rsvyinzpaxpv9uq7gomhva8h27ofl0.png","/map-media/tiles-54c7170546b6109bab59/14.png":"https://patchwiki.biligame.com/images/nrc/5/53/2gkakxatwxxgzn3hrwbsx3ber8wi9m2.png","/map-media/tiles-54c7170546b6109bab59/15.png":"https://patchwiki.biligame.com/images/nrc/4/4c/7bxsfgetq318kx8y5gyfrwlaznqek08.png","/map-media/tiles-54c7170546b6109bab59/16.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-216fd6ee47baf1806cea/01.png":"https://patchwiki.biligame.com/images/nrc/7/77/73cm7skpuv5lv1cd9rdrct0ka6oyrvt.png","/map-media/tiles-216fd6ee47baf1806cea/02.png":"https://patchwiki.biligame.com/images/nrc/7/79/a0hayhtfwkuxtqkr8wzgr63aqg4fid6.png","/map-media/tiles-216fd6ee47baf1806cea/03.png":"https://patchwiki.biligame.com/images/nrc/8/8b/otvr9ytezc4lbm9o95yt9e6nqpkip3g.png","/map-media/tiles-216fd6ee47baf1806cea/04.png":"https://patchwiki.biligame.com/images/nrc/5/51/0yatgeopoufngey1dmvz3uetjqr8hkc.png","/map-media/tiles-216fd6ee47baf1806cea/05.png":"https://patchwiki.biligame.com/images/nrc/f/fc/6zgu05ywxnxi41fe2y2c2dgkonesr9e.png","/map-media/tiles-216fd6ee47baf1806cea/06.png":"https://patchwiki.biligame.com/images/nrc/a/ad/1f38fsln62gsrfg01bd5n6g0tjlvlrt.png","/map-media/tiles-216fd6ee47baf1806cea/07.png":"https://patchwiki.biligame.com/images/nrc/6/6d/dypkcb3h6n8bpqtu6pfcuz01s14r7vy.png","/map-media/tiles-216fd6ee47baf1806cea/08.png":"https://patchwiki.biligame.com/images/nrc/0/0c/ghubi3z6utolai4wpcwu8hiii36f8bq.png","/map-media/tiles-216fd6ee47baf1806cea/09.png":"https://patchwiki.biligame.com/images/nrc/e/e7/s3jbue1ynyhflp20lvfxgyu0043t1ys.png","/map-media/tiles-216fd6ee47baf1806cea/10.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-216fd6ee47baf1806cea/11.png":"https://patchwiki.biligame.com/images/nrc/8/84/lgf80799dkoit08w9xc88hobvkse084.png","/map-media/tiles-216fd6ee47baf1806cea/12.png":"https://patchwiki.biligame.com/images/nrc/5/58/btug4ad47y48uydug9k406tn8w301ea.png","/map-media/tiles-216fd6ee47baf1806cea/13.png":"https://patchwiki.biligame.com/images/nrc/1/15/cb6cjnwlptl7zf4iclpa800dtvo4t83.png","/map-media/tiles-216fd6ee47baf1806cea/14.png":"https://patchwiki.biligame.com/images/nrc/2/2b/99hrjnny2gs3dab7raoy016ovgg7mzy.png","/map-media/tiles-216fd6ee47baf1806cea/15.png":"https://patchwiki.biligame.com/images/nrc/8/88/8pfvin3iw30bl2u59rm63ccmcyku33i.png","/map-media/tiles-216fd6ee47baf1806cea/16.png":"https://patchwiki.biligame.com/images/nrc/5/5d/kaqh268tfamz71s5wj1qk2vsodkdl44.png","/map-media/tiles-3d1d6db87c3aaf0d5759/01.png":"https://patchwiki.biligame.com/images/nrc/7/76/r7auy6hjpd9u3u1mxl7r7rwx6ulk486.png","/map-media/tiles-3d1d6db87c3aaf0d5759/02.png":"https://patchwiki.biligame.com/images/nrc/4/4c/ttttbj0xqf08532x3ugu7jtvrn63q9x.png","/map-media/tiles-3d1d6db87c3aaf0d5759/03.png":"https://patchwiki.biligame.com/images/nrc/5/51/khm0rp4nb66qaibio7rq7p9rjmxljg9.png","/map-media/tiles-3d1d6db87c3aaf0d5759/04.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-3d1d6db87c3aaf0d5759/05.png":"https://patchwiki.biligame.com/images/nrc/4/4f/mogaw9s6iza4erckx8s6fqp6qc3wls1.png","/map-media/tiles-3d1d6db87c3aaf0d5759/06.png":"https://patchwiki.biligame.com/images/nrc/5/50/4ag3nmadkhiqev9gkwshryrelg8tvgv.png","/map-media/tiles-3d1d6db87c3aaf0d5759/07.png":"https://patchwiki.biligame.com/images/nrc/2/24/r8jpn730bc16kk4as383rpziq9rq9a4.png","/map-media/tiles-3d1d6db87c3aaf0d5759/08.png":"https://patchwiki.biligame.com/images/nrc/6/68/rj6udi0hvmu3ptb8qm7rskwqijyllle.png","/map-media/tiles-3d1d6db87c3aaf0d5759/09.png":"https://patchwiki.biligame.com/images/nrc/d/d4/3lkwnff8tirogonw41wtd1et84hj68x.png","/map-media/tiles-3d1d6db87c3aaf0d5759/10.png":"https://patchwiki.biligame.com/images/nrc/9/9a/c80qga7cuq642a898jtofkhnnfnhis7.png","/map-media/tiles-3d1d6db87c3aaf0d5759/11.png":"https://patchwiki.biligame.com/images/nrc/7/73/gza33nyol9p267rrmj10zer2q087kw8.png","/map-media/tiles-3d1d6db87c3aaf0d5759/12.png":"https://patchwiki.biligame.com/images/nrc/0/0e/q687t4y9valrrwvd2ieuspbm5224t6g.png","/map-media/tiles-3d1d6db87c3aaf0d5759/13.png":"https://patchwiki.biligame.com/images/nrc/6/63/9hm8g46rb659103g2c04n2slx3hu9vv.png","/map-media/tiles-3d1d6db87c3aaf0d5759/14.png":"https://patchwiki.biligame.com/images/nrc/a/a9/frbsh1yte9d70wmsjt6tjxapkt9m84y.png","/map-media/tiles-3d1d6db87c3aaf0d5759/15.png":"https://patchwiki.biligame.com/images/nrc/d/d6/tn8baai8lnam2fp5x2kw0qw8kun2i5p.png","/map-media/tiles-3d1d6db87c3aaf0d5759/16.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/d6251717316c302f1bb9.png":"https://patchwiki.biligame.com/images/nrc/7/7c/pgryfh3ivnniwibga4dahm0esmd6hhn.png","/map-media/6e571d9c3e9058cd27c7.png":"https://patchwiki.biligame.com/images/nrc/d/d6/pjutnglae8ly9bytx1i6j6fsaongw7z.png","/map-media/e461ee767c57c6b16d09.png":"https://patchwiki.biligame.com/images/nrc/7/75/kaas2skk09mfwurjew3fmdyij7nc7ab.png","/map-media/87b475962539a30dea83.png":"https://patchwiki.biligame.com/images/nrc/1/11/a6yi0fqfk2877zzcj0bixe0mvequ94p.png","/map-media/34d75171913304c688eb.png":"https://patchwiki.biligame.com/images/nrc/7/7a/hmtus0il23qrlr6h90eh37la7dg127t.png","/map-media/ae361a469a4a117c2b86.png":"https://patchwiki.biligame.com/images/nrc/7/76/sdibelxkj6dtossi299yqrrcphjdd7i.png","/map-media/bb619d9f0be2f4743945.png":"https://patchwiki.biligame.com/images/nrc/e/e8/amsvyxkj8x34wefldtpjs9szd4ukvna.png","/map-media/a51b86df616fc1b7bb1f.png":"https://patchwiki.biligame.com/images/nrc/4/44/9ggklyi7evdu2jns9ehhu3kc1x4q5xy.png","/map-media/a010300fb5a448158629.png":"https://patchwiki.biligame.com/images/nrc/7/77/iazf7tgi59w00bctm7o7xugenug7byw.png","/map-media/5e1d3eb561e2f95bd31c.png":"https://patchwiki.biligame.com/images/nrc/7/7f/63vmneq1ergj0u6dixs72kbtz8aqj4g.png","/map-media/fb6d6d78981819bf4993.png":"https://patchwiki.biligame.com/images/nrc/2/2f/g1v9vd4xit195017r6zycmvlzw6gqfo.png","/map-media/fc808b881d102c10303b.png":"https://patchwiki.biligame.com/images/nrc/9/95/fdmi80p0fdoumwp57lxx98gfy0p9mkp.png","/map-media/89d454f2e89b72c7d984.png":"https://patchwiki.biligame.com/images/nrc/6/67/aybvnyggb92rm0b0id9unlcai02wv5x.png","/map-media/a13993742bb48ab5a7e5.png":"https://patchwiki.biligame.com/images/nrc/7/7a/dcufmhvntrbt2dfdgnymvpegodeb96q.png","/map-media/cb4e18e65b23dff850d0.png":"https://patchwiki.biligame.com/images/nrc/5/5e/nwvdu4rur9gqbrxsqqurg1shinm0hc0.png","/map-media/956b1dfc6937864919bb.png":"https://patchwiki.biligame.com/images/nrc/c/c4/pw23ifyfedv1xenwhtqvcp2uvbkhk76.png","/map-media/fb5f2119919e9ce9b977.png":"https://patchwiki.biligame.com/images/nrc/6/6a/5gv14h27qz15a292rsmcmew2vtvl3pt.png","/map-media/f1b164d6e1d029620118.png":"https://patchwiki.biligame.com/images/nrc/0/09/l37y4vz6m61983d0frbldbdsohpqxk7.png","/map-media/e206663f62378bf2d7cd.png":"https://patchwiki.biligame.com/images/nrc/c/c7/c9eenqcrqlpm2c0od2sf6o0kbmrfe50.png","/map-media/4f5f6a765d22b4364744.png":"https://patchwiki.biligame.com/images/nrc/c/c0/bhcf4gc5yqgbjad0pexrbvaz2fpn4b2.png","/map-media/35379b75e60c251e95c3.png":"https://patchwiki.biligame.com/images/nrc/7/73/pjrutk7171n45d8s17wnd4st6oz7psh.png","/map-media/a7c832487391b880957a.png":"https://patchwiki.biligame.com/images/nrc/0/00/0o3wo0hkmx1d5cfpl6m8in4vyi2qgz8.png","/map-media/a0115461fa3a9b42119a.png":"https://patchwiki.biligame.com/images/nrc/1/10/o76a4cyzhwxw83y5mdw3obu34x20j5r.png","/map-media/74de5ae54813d3d72912.png":"https://patchwiki.biligame.com/images/nrc/6/64/aq94yh30sv2nmv2wip253qpl92sea68.png","/map-media/4e24bdbd7c5d3dca7cec.png":"https://patchwiki.biligame.com/images/nrc/b/b0/6qogppaucbc9vkau3br8zmc489d2ey9.png","/map-media/bd4047089a5af6c37712.png":"https://patchwiki.biligame.com/images/nrc/c/cb/34z99jeu30yadoc10j6490c139glew9.png","/map-media/994311198a5f1e11b036.png":"https://patchwiki.biligame.com/images/nrc/c/c8/rpcovu7bovjsgfz9757l0z5srtdv3wg.png","/map-media/e432cde25b7c1b1aebdc.png":"https://patchwiki.biligame.com/images/nrc/4/4a/0onus6hkvt2x927qakqsxghdzvdxpwa.png","/map-media/6d0974e0b107bbfe4761.png":"https://patchwiki.biligame.com/images/nrc/6/60/mebtr92zdlbvmpx8ujhlmqcom9lpg6n.png","/map-media/68e4686a82ce01bc70f4.png":"https://patchwiki.biligame.com/images/nrc/d/d9/7qsncvokm4oj6mrqybvz9y6m67i27mt.png","/map-media/ff71826874fe945291d1.png":"https://patchwiki.biligame.com/images/nrc/0/07/5z23asb943j9rflge5sfnto2l5klxox.png","/map-media/4bde46dd7a8ba72691df.png":"https://patchwiki.biligame.com/images/nrc/3/3f/o80q0lu778zwlh9qgjlfytgv4q4deja.png","/map-media/577b84f7a1de3dc36314.png":"https://patchwiki.biligame.com/images/nrc/f/f9/90efnry7vhpy9wh84n317mgy04npmwb.png","/map-media/e508fb2d80879bf65c94.png":"https://patchwiki.biligame.com/images/nrc/c/cb/qp794qhrnuj61m3blm6ebw0n7jy78o9.png","/map-media/b7ca4889fa69bfa5870d.png":"https://patchwiki.biligame.com/images/nrc/f/f4/cwa80g9gra5a1h5hwmz3a8fxa87tq1s.png","/map-media/f2ca521ae57bb40dae94.svg":"https://patchwiki.biligame.com/images/nrc/4/45/g2lkv0kt8f80bss2vot0eir3bay6t1g.svg","/map-media/6227421a7f5034f20278.png":"https://patchwiki.biligame.com/images/nrc/e/e5/kafrl1nyyu3r9o6q0ien852ir1vwk4a.png","/map-media/87d6f6f2d1e0483ebc90.png":"https://patchwiki.biligame.com/images/nrc/e/ee/3zlcf6zq94vpanxnoaf89z8ryyc4wu7.png","/map-media/fe1d704c811947c5c309.png":"https://patchwiki.biligame.com/images/nrc/5/55/917ct1jht5zjf6d6ftyfgwaqbqmi4u6.png","/map-media/262ee968fb5405a812bb.png":"https://patchwiki.biligame.com/images/nrc/4/4b/ifb5jnhil9kfur7px1yftlfah8zhcmt.png","/map-media/02c18e63c167e8051922.png":"https://patchwiki.biligame.com/images/nrc/8/83/hs6vx7ljpikp90jihceykugitp8fba4.png","/map-media/a0c11514a71c96c17980.png":"https://patchwiki.biligame.com/images/nrc/f/f2/55rfsc6gwyr8rp2r3o6bw2adwvm0u12.png","/map-media/0866579a5f81c0678730.png":"https://patchwiki.biligame.com/images/nrc/3/38/pjf7ksa2inroq78lg923jb5i9ud7735.png","/map-media/2cabdcf1ab6273d9d069.png":"https://patchwiki.biligame.com/images/nrc/8/88/epyqxi8o0xqf48yncw71zxe9237av8k.png","/map-media/c2c347798165f5e73fe3.png":"https://patchwiki.biligame.com/images/nrc/f/f9/3epvz4vzgnrswm77jg2xwv7sy5e8n5y.png","/map-media/457ba5a911f9bf5f70d7.png":"https://patchwiki.biligame.com/images/nrc/a/a8/t6tbqngve137vc5wzn9zdmcsg1jp9f4.png","/map-media/7e316fa6db6c383fa969.png":"https://patchwiki.biligame.com/images/nrc/0/07/ft5ssyy8usds144r2apm1rvaqgtl2et.png","/map-media/b14b4ac05dedac6f980a.png":"https://patchwiki.biligame.com/images/nrc/1/1f/0fawqh4mo6xfhqhda2mkd9jit4lcgnb.png","/map-media/4e52bb45e28d8fbcded8.png":"https://patchwiki.biligame.com/images/nrc/a/aa/8ucmkwx205r89kthoujgyct4ex3usxn.png","/map-media/e2800f8b05e25df58438.png":"https://patchwiki.biligame.com/images/nrc/6/66/nh23rn0vb6mmk6pdx6grnhf19qvlh8i.png","/map-media/c0ef5a4e0b64b137fd23.png":"https://patchwiki.biligame.com/images/nrc/b/b0/76cxy5ki6bae4srlfmsz8ms9ej03m6y.png","/map-media/7a834e21d939e738e859.png":"https://patchwiki.biligame.com/images/nrc/1/19/mhtsvahuv2emcdb4mtg8hv3gy3wwig1.png","/map-media/7f759ae9db3cfd0f8695.png":"https://patchwiki.biligame.com/images/nrc/0/03/6i9icgucsl9udn60rtngk6lns1v2ls7.png","/map-media/4b20d27c33c24e6de344.png":"https://patchwiki.biligame.com/images/nrc/3/3e/bq9llmyqicxtaie4z9fv0y1asezy9zm.png","/map-media/1e8bbea516f2793dfe97.png":"https://patchwiki.biligame.com/images/nrc/8/87/0mztdnn0ezi5yrgrys9uflsb69e11xb.png","/map-media/a075675d3cb72a27f982.png":"https://patchwiki.biligame.com/images/nrc/9/92/a27zj53s5m40p9kb9q9v9wt70acxc24.png","/map-media/02584c5977c2568344b5.png":"https://patchwiki.biligame.com/images/nrc/2/20/bwwmqiiin0rcgqrach597sxovhbcg2u.png","/map-media/843b697b704e71666429.png":"https://patchwiki.biligame.com/images/nrc/b/b8/gs8y15s355mmh9ktpledfxlza39uvhx.png","/map-media/9c4a7122c13f6b5360e8.png":"https://patchwiki.biligame.com/images/nrc/b/bb/tb04lckoztoeodpnd90f7a2ns0iemul.png","/map-media/3e6a779c1c1c751dbbe1.png":"https://patchwiki.biligame.com/images/nrc/f/ff/gcvo7qptpp1f8gbkrjrd288mbcgzi9j.png","/map-media/e554cafb2d9fccdceede.png":"https://patchwiki.biligame.com/images/nrc/6/66/fqu75r62ikt77ap320dkpancp0xo3ch.png","/map-media/38dc1bf3515cb3641fbb.png":"https://patchwiki.biligame.com/images/nrc/0/0a/df1kk2drm1z0h0ipmx14st0eriudrxq.png","/map-media/5b7cd42c98e950b2c17d.png":"https://patchwiki.biligame.com/images/nrc/a/a5/hc4iubrlj64uqmw4fmoxewb17qeizes.png","/map-media/9ff1747d0f7f1e19fc74.png":"https://patchwiki.biligame.com/images/nrc/4/4e/ansz7utcnam40nckgyw8hsb26t6zkp6.png","/map-media/0ad5827aed44d99b4396.png":"https://patchwiki.biligame.com/images/nrc/8/8c/6bnm71szdu8owh9r9i8ccy6qwzq1s2x.png","/map-media/d5cd39d298467bca6310.png":"https://patchwiki.biligame.com/images/nrc/1/1c/tqvhle85nujnbnxo9fcu23evujlu54p.png","/map-media/929f87eacc9786b9049b.png":"https://patchwiki.biligame.com/images/nrc/d/d3/omjhvzwmmmyg63espo4gsec8tzy7k1z.png","/map-media/8257f45366fee7b801d4.png":"https://patchwiki.biligame.com/images/nrc/8/80/edr6ut42a72p0bge76w17tng45r4nrb.png","/map-media/f2e915acf80b6006526d.png":"https://patchwiki.biligame.com/images/nrc/4/48/868cp8kb0pe6xlg2535ya9h1dsr15v5.png","/map-media/e4a15cfd66b6c8349f57.png":"https://patchwiki.biligame.com/images/nrc/8/89/47v7xg1wmje8vuygnjb4k31xomomjte.png","/map-media/7b10697bc607a3c9ef7a.png":"https://patchwiki.biligame.com/images/nrc/2/22/qvuqiz0ukwsemz9eusd53l77zlyq4w7.png","/map-media/7229c52ca0c5e3e5417a.png":"https://patchwiki.biligame.com/images/nrc/e/ef/a8qk68i7p1lbpb5anxf94g36ow1ar6y.png","/map-media/b183c5e4286301eec410.png":"https://patchwiki.biligame.com/images/nrc/2/22/rinqxqlbrobzvdv3i8w2pfz2mbbnobu.png","/map-media/4433b8e9cb6ecbcf3050.png":"https://patchwiki.biligame.com/images/nrc/9/9e/6lifjpocs40sa90og9p21kpgk62n9e6.png","/map-media/4d1164c25a1ac39fa09e.png":"https://patchwiki.biligame.com/images/nrc/8/85/oqnsqagk6zafrc6qzgmecc8sl9psehm.png","/map-media/d7866347e75e4c23f5ba.png":"https://patchwiki.biligame.com/images/nrc/9/98/euufjb5uwot5k3fxgu2lubm2p9xacis.png","/map-media/56170a9e170d7dbfb961.png":"https://patchwiki.biligame.com/images/nrc/e/ef/h55omygzq38mzswsa5unc6wcatdfpsr.png","/map-media/fecc33f5f915e3fa5532.png":"https://patchwiki.biligame.com/images/nrc/d/d5/bu7jx8jtrjs9fxaz4orb51vv34g5usx.png","/map-media/84c111cf602b283a5b5e.png":"https://patchwiki.biligame.com/images/nrc/8/84/1diof1aevgi1uaghvhb7tslchq9ivei.png","/map-media/23e80176b47dfdb87a7d.png":"https://patchwiki.biligame.com/images/nrc/1/1f/nuz8c4fkdc95pvfe7z0xonr5mh7byrr.png","/map-media/39916cf4951cff963934.png":"https://patchwiki.biligame.com/images/nrc/7/7e/4phgvgj688r2dhlhn3l226p7xr34v3b.png","/map-media/958d1c44d65ad163ebe8.png":"https://patchwiki.biligame.com/images/nrc/4/42/4bwk3h4wupclfo3s6cqmcifwahetpbi.png","/map-media/a6139a6a8bc983a4b624.png":"https://patchwiki.biligame.com/images/nrc/6/65/ekr08xtl4akgrj1m0rm9pwu7pmoqd2a.png","/map-media/ceca68c2914b26d11f54.png":"https://patchwiki.biligame.com/images/nrc/6/6c/387z0ajazn7zv6f3q23akl7b5vy6naw.png","/map-media/cc86b3e0e2f8d5b6b3f6.png":"https://patchwiki.biligame.com/images/nrc/f/fc/exm00tk08fcn3xlmvd5peggfpiljkoe.png","/map-media/68a05d99324fa97b8819.png":"https://patchwiki.biligame.com/images/nrc/1/11/fwxpen4vzg5dw80e2lfhqehau57kqhu.png","/map-media/6fd8826f5070303e8c00.png":"https://patchwiki.biligame.com/images/nrc/2/2a/8sasccvcv6gb483830fct9zhjhmii3y.png","/map-media/5cc81e3af1989c6b8719.png":"https://patchwiki.biligame.com/images/nrc/e/ec/hfe7ikseaje50cy9jzn7ymku3bnye3e.png","/map-media/0d454f1dea35d5fc6d6a.png":"https://patchwiki.biligame.com/images/nrc/9/97/de6t3ldkjk95temctardtumn9x3sdkm.png","/map-media/9e5fd310d044ccf090fc.png":"https://patchwiki.biligame.com/images/nrc/b/b8/km3pb0y5wjqn3nf9id2hxzgokbv2u8e.png","/map-media/475497b3a19e1efedccf.png":"https://patchwiki.biligame.com/images/nrc/f/f5/2jju1xhzkxp7qnxe9elyz951spazg6f.png","/map-media/e0f549e1ff4615d79905.png":"https://patchwiki.biligame.com/images/nrc/b/b7/4yr6rdzxrxfxzfle1zgdjxdjptqxsmd.png","/map-media/4785ec0881c67c229e7e.png":"https://patchwiki.biligame.com/images/nrc/a/aa/q1ee4re6jkr1loxx6waglcr3r44donm.png","/map-media/13a82b4f4a728505491c.png":"https://patchwiki.biligame.com/images/nrc/9/99/8vbolh78pzpja7o670ks6ingua58hfa.png","/map-media/3a8d8c3b1571bad748b1.png":"https://patchwiki.biligame.com/images/nrc/f/ff/3mb5pftu44esjfd2zmefmibx1ldx1uv.png","/map-media/6b483e91d2f3f9367639.png":"https://patchwiki.biligame.com/images/nrc/c/c7/0jxd3atdcl8xt1cvf3pqj2hbvyvy6tv.png","/map-media/29e58d2e8d144e67f378.png":"https://patchwiki.biligame.com/images/nrc/5/58/oukrgjblqjxcy0cdd7159aels2uedde.png","/map-media/fd159d5628fb2bf445bc.png":"https://patchwiki.biligame.com/images/nrc/5/54/rdr2ldcqz5by3f3a5bo5b1jhq3blhc3.png","/map-media/410972cf90a86fb4e386.png":"https://patchwiki.biligame.com/images/nrc/4/43/rzxcdogoklchbqle5o3drz2odwyojn6.png","/map-media/ae933f25cf55b76a3a81.png":"https://patchwiki.biligame.com/images/nrc/e/e6/98b78zzx4vl2g8wz5s2g9og7jwsz0by.png","/map-media/f3775aa15f2f2afeb0b0.png":"https://patchwiki.biligame.com/images/nrc/d/de/8gbirp0osuu8i1tgpas7osx29gcqjis.png","/map-media/c00d466d3bd6d8b52b39.png":"https://patchwiki.biligame.com/images/nrc/5/5c/6ti5duotx0d2wesgiw4zo2n0g7peq40.png","/map-media/7038596875fe4ec40b9f.png":"https://patchwiki.biligame.com/images/nrc/d/d7/r68y52iabhcwsm0tjxdknzxn7es7olw.png","/map-media/789e1eca1131a7cf66f7.png":"https://patchwiki.biligame.com/images/nrc/d/d7/o5fcich9cjtrer3hxp00cyuo27tnh4p.png","/map-media/aff6d754c9be0df2d008.png":"https://patchwiki.biligame.com/images/nrc/6/67/6zdz7towr9okwr6drptinl086owgcue.png","/map-media/7f518e38ef7ad6b2ff66.png":"https://patchwiki.biligame.com/images/nrc/2/21/rgosrdawb2pug7iqh5ijqbu98cymyew.png","/map-media/18ff24ee0faa1ff71287.png":"https://patchwiki.biligame.com/images/nrc/8/86/75dyq96ltjsw2yh3t79tdmutjzn590e.png","/map-media/bd06d074b4906c7e7e75.png":"https://patchwiki.biligame.com/images/nrc/a/a7/5kdg55c68nyuckiyj1vw6lbufjlbpo0.png","/map-media/9855d1339ae4916177fe.png":"https://patchwiki.biligame.com/images/nrc/b/b0/629tdhcwmwem6r171bpd966ldpoo2mz.png","/map-media/af2a295ddb0a1123d7fd.png":"https://patchwiki.biligame.com/images/nrc/8/86/4yqhsce13i2ldhuhxx2eshhuyxla2lp.png","/map-media/df51b9c1b60a06e73566.png":"https://patchwiki.biligame.com/images/nrc/7/7e/k7vfqah4bxnzhgkineeudoj2p06e8yd.png","/map-media/1fd63bbbec401eb31af8.png":"https://patchwiki.biligame.com/images/nrc/0/03/op1blouse30wps6i6e0fz3hxw0hgul8.png","/map-media/4c560f5fefd2261b37ac.png":"https://patchwiki.biligame.com/images/nrc/8/8a/46s54vixuj70uhxup66ml5j8p8y71e8.png","/map-media/f4cfce7afe3a51a081bf.png":"https://patchwiki.biligame.com/images/nrc/b/b4/1paxs7zq422p4ichajnh6d8ssusha48.png","/map-media/d4af20b97bdcc8087a88.png":"https://patchwiki.biligame.com/images/nrc/5/5d/c2wb8e63x4gkorimv5ogq9ft23lwu0n.png","/map-media/6de50b6350b69026e3fc.png":"https://patchwiki.biligame.com/images/nrc/2/29/km5bmbfsruyot7efd8r6mfu5gefvzgp.png","/map-media/90d22fd2347ac4706248.png":"https://patchwiki.biligame.com/images/nrc/b/be/9iczdewrno9vpsz89589c4mgke7yeod.png","/map-media/6eb470382e8715283217.png":"https://patchwiki.biligame.com/images/nrc/a/a9/aq4cjnr3lvvz1fbsqqv2k7in2pqz63a.png","/map-media/10785cb7a62194ff5973.png":"https://patchwiki.biligame.com/images/nrc/d/d4/dsgoao04vl3c7ineo8j52kbijhoi1eg.png","/map-media/5c3edc2c2f72a33ed125.png":"https://patchwiki.biligame.com/images/nrc/5/51/f6xehhz9ub44rh7ssda65gauhcdzonv.png","/map-media/f0c301c1a8be03460a97.png":"https://patchwiki.biligame.com/images/nrc/6/62/90xq621eb0jrjcz1zvc34zrsntbnyjf.png","/map-media/ff1db249b04d9f27067d.png":"https://patchwiki.biligame.com/images/nrc/d/d1/i6830tu2sdb3tzkhlumavr2dcildvl2.png","/map-media/fce3563bfddf338c198b.png":"https://patchwiki.biligame.com/images/nrc/b/b1/dcs9cjbz6hc43ew9g7g4at9y3knuwiw.png","/map-media/3a7a3056a1249bc4a6ec.png":"https://patchwiki.biligame.com/images/nrc/0/04/h8twwsxdo71r2gb5so6lw3ydbgzug8o.png","/map-media/ef6a75aa722c2ad970e2.png":"https://patchwiki.biligame.com/images/nrc/5/5a/qxzeabgaw2wv7jcgfh7wyygjskwsvji.png","/map-media/986e87ffa6d29f181133.png":"https://patchwiki.biligame.com/images/nrc/d/d3/agctpdsrjezzzywcsityd4ngo59hq1f.png","/map-media/029e48f4219c6361c633.png":"https://patchwiki.biligame.com/images/nrc/9/96/j3xewj45n8zj94sdnqo7fxgsrvf2ox7.png","/map-media/9ebcade4438165f80973.png":"https://patchwiki.biligame.com/images/nrc/9/9f/q751s9h4hm8ei68h5amkqbitkgw84s6.png","/map-media/58391225c82b860fd3ca.png":"https://patchwiki.biligame.com/images/nrc/5/55/jam2c4zf2sy1tvs0kn2gelxig3aj24o.png","/map-media/9d91c2fab1411bec15d3.png":"https://patchwiki.biligame.com/images/nrc/4/47/67u6h5r9p2t3f9jna9sl043ibnu3rzl.png","/map-media/9e3f371aac267cc01546.png":"https://patchwiki.biligame.com/images/nrc/d/d6/eai5qmr7zxj1ya5nveexe5lb47nwocn.png","/map-media/7648e62c286aa7c3b219.png":"https://patchwiki.biligame.com/images/nrc/0/04/iaxqafgq6jup7xj1egfgp13olrk6cs5.png","/map-media/972c94beae5ee786f61c.png":"https://patchwiki.biligame.com/images/nrc/1/14/fgjjg2wb19epeegulyz0jcsaq8zfrry.png","/map-media/c932702dd2c0358e493c.png":"https://patchwiki.biligame.com/images/nrc/8/8a/ke4j9azgcnr6nxj28dh6tgu8z3eu3iz.png","/map-media/992397f6be451f4038a7.png":"https://patchwiki.biligame.com/images/nrc/9/91/is6mjlvdlhmr7psazhtx7bvj4v8g83n.png","/map-media/507add93a01c34211dba.png":"https://patchwiki.biligame.com/images/nrc/b/bd/qbjx82cfvmubfyyaxa55rbvj1j9iz65.png","/map-media/63da6d3b06d4225d47b5.png":"https://patchwiki.biligame.com/images/nrc/7/7d/spc68muupa0sdljv3s8twy7dgb0kua8.png","/map-media/215e38475bea4e8aa819.png":"https://patchwiki.biligame.com/images/nrc/d/d1/mtczn540p0tomr6le79t49ko4sewva0.png","/map-media/c42b454b678311dad906.png":"https://patchwiki.biligame.com/images/nrc/d/d5/lb576g6fw4886oi2nio1irp7zf4vrdo.png","/map-media/4eb294b24c534279c1d6.png":"https://patchwiki.biligame.com/images/nrc/7/7e/dwg5notd9nzwu8dsj5daxl8srk1268b.png","/map-media/7f9b716d93196fb6431b.png":"https://patchwiki.biligame.com/images/nrc/1/11/7xv9drmv84j92axj90vtocspscrbmuy.png","/map-media/e5ab2b10a67b97855dc3.png":"https://patchwiki.biligame.com/images/nrc/0/07/awmvw5jjpi30rq384kfn3jlykck3v7i.png","/map-media/35bb6cce8f267baf9a54.png":"https://patchwiki.biligame.com/images/nrc/6/67/3wov5knrkeg1qfeu3uyuivmbkq89zdm.png","/map-media/51b9f7b25801dba6471b.png":"https://patchwiki.biligame.com/images/nrc/7/70/4hv2804u3l3e4w9mogthf5pevwhxjvq.png","/map-media/859f5e1f35ffd146b84d.png":"https://patchwiki.biligame.com/images/nrc/0/0d/mnajtnk9xwt3vw8bx1x893z5j8py7t5.png","/map-media/31138ddf1e031b9d5f2e.png":"https://patchwiki.biligame.com/images/nrc/3/32/939pb2af0ifsc28lqucfz8wbpdc8dy8.png","/map-media/1367f2b51920439bc92f.png":"https://patchwiki.biligame.com/images/nrc/a/a6/73bf3fwelg0ng5clkg84pwx61dcjmpo.png","/map-media/c948e3c8f5f4a6379491.png":"https://patchwiki.biligame.com/images/nrc/3/3c/c7ns8dvm039zeffsysaz87apb5eoem7.png","/map-media/835dbac3e010a878e49a.png":"https://patchwiki.biligame.com/images/nrc/d/d4/prfj3s8pro5ls4v99hdgt2xd4ix606w.png","/map-media/e19f67870a3791656e56.png":"https://patchwiki.biligame.com/images/nrc/a/a9/h0qfv6oyx5xhc3cikihirutigdot7ps.png","/map-media/e999929a53ed9e309cf5.png":"https://patchwiki.biligame.com/images/nrc/a/a8/jkoy9nt6aoyibdzhor9aafqudxyxxzd.png","/map-media/bff232772f94d2a6df6d.png":"https://patchwiki.biligame.com/images/nrc/5/5d/3ghzwz5xocha3fnw2o3mu06ak7cnug4.png","/map-media/3cc20e052c82fe2958c7.png":"https://patchwiki.biligame.com/images/nrc/b/be/3c5atfrzgsj87almdo7nw45agcajiys.png","/map-media/0b5bf5233d131ad70db4.png":"https://patchwiki.biligame.com/images/nrc/d/d3/f3qsn1e7hcgud7m1rtr4vrqynpxgcpf.png","/map-media/574e8cc7bf2002683732.png":"https://patchwiki.biligame.com/images/nrc/5/5f/pqf9eb7eb8lfmh2c7swxaz1560xn6sk.png","/map-media/c22439525ab88255b3e3.png":"https://patchwiki.biligame.com/images/nrc/8/8b/1sg2znkmk17z90iytn9d74dl3fi5nxd.png","/map-media/a335b206bf0feb644628.png":"https://patchwiki.biligame.com/images/nrc/9/92/krci3tscmji6zn2uvl91ehwifmtkw7m.png","/map-media/3d200a2a0c9a7df08945.png":"https://patchwiki.biligame.com/images/nrc/3/33/h8lbxyoamcp2ai3mxdlnc2htxu3xrtb.png","/map-media/1e61b30231bc8775a2cf.png":"https://patchwiki.biligame.com/images/nrc/6/6c/ek7nu2327ztknwij7vgyojfb3hal3we.png","/map-media/2506bfd0b6175e6393c8.png":"https://patchwiki.biligame.com/images/nrc/9/94/1b29pw6mlcclszu9sfn1oleumcpkpkv.png","/map-media/c0c0bf4c91b6489fc991.png":"https://patchwiki.biligame.com/images/nrc/e/ee/sa3xsyd3zl81g9acq2m7g4gwibzdnrx.png","/map-media/3b8066eba4a8b31c032b.png":"https://patchwiki.biligame.com/images/nrc/f/f3/oa8tlnfmf6s1ht44kz7jd8nbnv4y2m8.png","/map-media/bd8508437110f6fb3d26.png":"https://patchwiki.biligame.com/images/nrc/5/51/id4pxr3b9so0vxte0pf43u3yj74cvcq.png","/map-media/6563c21f1e475f5f0bb2.png":"https://patchwiki.biligame.com/images/nrc/8/85/lm45vipox46fvbfvs6vepznjfccf2il.png","/map-media/62c1555afc6b36fbf731.png":"https://patchwiki.biligame.com/images/nrc/8/82/8kw2b919sfi5s98t9j7hl7kqwpikxaq.png","/map-media/403869b005f660f3dcd4.png":"https://patchwiki.biligame.com/images/nrc/e/e8/5n0ddfrr4hjghy0uxo52phqw7g2zk0f.png","/map-media/9286e34e18cb54913fe0.png":"https://patchwiki.biligame.com/images/nrc/c/c0/bfqet8w0wjo5rc2askjld5tmyvdvn1a.png","/map-media/6c4628367a6afe4e5be1.png":"https://patchwiki.biligame.com/images/nrc/b/b5/3hvu056ebjqql44y348ifwfh4zskdcs.png","/map-media/87deef65dbf3f8b69535.png":"https://patchwiki.biligame.com/images/nrc/7/7e/qt5yt6pc6isrlmuze7gbhzlwndwjj04.png","/map-media/57b8b527822ac7a9abd7.png":"https://patchwiki.biligame.com/images/nrc/e/e9/hj0ak061iwtc4w5ks0s4573utqebs4c.png","/map-media/6420092e3390c8434f88.png":"https://patchwiki.biligame.com/images/nrc/c/cd/ibagrru1xtgbs1ccbpjkau1z1n7ef97.png","/map-media/96f12042a8fd557de8fa.png":"https://patchwiki.biligame.com/images/nrc/b/b8/rey40ghqphpwflwl9h6kdr2ofiugiig.png","/map-media/04332c6152e1a40f2e4b.png":"https://patchwiki.biligame.com/images/nrc/a/ab/6kdkuahevs3co8e1wf9pu6t6s5zu2zu.png","/map-media/5970feef4a7218812f39.png":"https://patchwiki.biligame.com/images/nrc/8/82/5e2qtxltdn794ow654br7ge74cocmtv.png","/map-media/d456771399d032017380.png":"https://patchwiki.biligame.com/images/nrc/a/a6/ebxd39flrlhxozmfovh3235ws7ke308.png","/map-media/0b8f41b4516031376a03.png":"https://patchwiki.biligame.com/images/nrc/2/2a/dzq7a0dneon8fyruta89h3y8z7ww7v1.png","/map-media/25f94ece806f89d7a437.png":"https://patchwiki.biligame.com/images/nrc/c/c5/ol35s2gqyqittiwe8zanjrqmw6s13c7.png","/map-media/8bc163f6fa6829dab554.png":"https://patchwiki.biligame.com/images/nrc/6/6d/niajhgtkjip3eclv20kg4q2vpye0lf0.png","/map-media/0420411dc4b37add6288.png":"https://patchwiki.biligame.com/images/nrc/6/64/be3g81e31eq4w1pymxneshsct3fks0h.png","/map-media/00d655a4a7da8d6aab62.png":"https://patchwiki.biligame.com/images/nrc/6/6e/jhiqujr5x1n90jaxoczi61yaoztgsnh.png","/map-media/393dff13194a817cefe6.png":"https://patchwiki.biligame.com/images/nrc/d/dc/6kbhno4089cib4ckvea6tit8fz62r1x.png","/map-media/00f1b64792bb6fdc507b.png":"https://patchwiki.biligame.com/images/nrc/b/bb/tbt90ch9r35gubl3ngve2nb62p7iymo.png","/map-media/6f32efb63db596c0ce8e.png":"https://patchwiki.biligame.com/images/nrc/d/d1/hqzi0c6lw5gt50qz7chn7f31z2fe41i.png","/map-media/47cf5bcfbb3fce5a0cdf.png":"https://patchwiki.biligame.com/images/nrc/f/fa/i7yuv90wg0mdh2ae8hbvkohoogu8o4d.png","/map-media/82618b9575efb9d12796.png":"https://patchwiki.biligame.com/images/nrc/4/4e/9fd6av9r4ea9sqe8iu8psdnywmkdscx.png","/map-media/1f0c56b271eb6e914b39.png":"https://patchwiki.biligame.com/images/nrc/4/42/0l4w91jbl70na19szgytz5vl54t0jwe.png","/map-media/96881778940c7caec3d4.png":"https://patchwiki.biligame.com/images/nrc/2/27/fbufwhzrqgthipe00ve5bp6vbskbbul.png","/map-media/3b705844e2750fb6ab3b.png":"https://patchwiki.biligame.com/images/nrc/f/f2/bmxk0bjx7tx3izuve6lbx3vjzezpjrz.png","/map-media/5675a26fd3e948e50dda.png":"https://patchwiki.biligame.com/images/nrc/2/23/cuhq21gm9orhwprp91s0bovtfodvwhf.png","/map-media/ed48342be001864cc115.png":"https://patchwiki.biligame.com/images/nrc/5/50/lacva113rbcm96a01nan4ixdmqb4jg8.png","/map-media/01d120a59d3fe232ae5a.png":"https://patchwiki.biligame.com/images/nrc/c/cc/qiru20hk565kphyn5469augwkseyvov.png","/map-media/abf20cc7267f0a6a5d76.png":"https://patchwiki.biligame.com/images/nrc/e/ef/rb6cxcch68fw6g2y09oltwe9pmht3y6.png","/map-media/767066264d816e714b5d.png":"https://patchwiki.biligame.com/images/nrc/3/39/lhcr7yn04ctph1h6025froygl07fibz.png","/map-media/1afba6c832878517d17c.png":"https://patchwiki.biligame.com/images/nrc/d/dc/rayqe6ytf5zzrcsboywcsv732x5wjd9.png","/map-media/e69bc988b5859b0d1a45.png":"https://patchwiki.biligame.com/images/nrc/7/7b/8h8h1stto9nfcpa34qkfcdpnwb3dwcj.png","/map-media/1e081226ee27bebe3ef4.png":"https://patchwiki.biligame.com/images/nrc/1/1a/q6wdscyjcrjgkobsdc5lqjtm134kpwp.png","/map-media/69af3be3c21cd6b8fa25.png":"https://patchwiki.biligame.com/images/nrc/a/a7/6acw8f9q2zgobo32esnsqc5unj89tn9.png","/map-media/96fbe5f0b107c6c98ef9.png":"https://patchwiki.biligame.com/images/nrc/3/37/5ijqoy9as2iuu812222j0d48kg77l4i.png","/map-media/d941a3fac7aa099365d1.png":"https://patchwiki.biligame.com/images/nrc/9/95/54917gcmjgn263hjmatyb1740waf95d.png","/map-media/0ec98df9df5c043a3c41.png":"https://patchwiki.biligame.com/images/nrc/e/e5/iky439x8324mj6mf3up5farpgm1jzi2.png","/map-media/74f2d42b6f38d72e6aa0.png":"https://patchwiki.biligame.com/images/nrc/9/99/ajdavwtushrsjrzceb3gppr12n3610c.png","/map-media/d7898d7242c3750ee75d.png":"https://patchwiki.biligame.com/images/nrc/a/ad/j3f631rg27xxyogvhdrpxv9vc3k2rqv.png","/map-media/c736b2991a1a33166862.png":"https://patchwiki.biligame.com/images/nrc/5/5e/8nfr7ujl12q3tsvruw9gnszh99rhl3x.png","/map-media/f3248aff5e9a699ba63c.png":"https://patchwiki.biligame.com/images/nrc/5/59/eyh6eodgc6wz9go0qigkxltnaxcr909.png","/map-media/422fcb0ec72c361a8ee8.png":"https://patchwiki.biligame.com/images/nrc/d/d4/nck16i43ttz3h2soh47znimna2r8jyo.png","/map-media/e3f93b921a0657df8f3f.png":"https://patchwiki.biligame.com/images/nrc/0/0a/teftxhycra4gozenb92xgk9db1scs92.png","/map-media/21a02a8f6f9734c9a069.png":"https://patchwiki.biligame.com/images/nrc/6/60/ej83mtk3bomi2k2cq4np46v06laz8ei.png","/map-media/46e332deff205cb21909.png":"https://patchwiki.biligame.com/images/nrc/e/e9/ijqdjiozfkz2cf6vjulhs1u5guv4rdv.png","/map-media/e566bdfc0fc5765bf12f.png":"https://patchwiki.biligame.com/images/nrc/9/92/bw87wan2q5m91ibnnb07tkhpk2sif4f.png","/map-media/65d7b9b8b809985134e2.png":"https://patchwiki.biligame.com/images/nrc/3/3f/ds2e672xdosyyxtecvzs5gj9ddzgq2i.png","/map-media/7b66adb8ab539c47ccb6.png":"https://patchwiki.biligame.com/images/nrc/1/1b/idjfiw49le8nemjre9yy4xyax65rl8v.png","/map-media/a47b3594b1b9573a7259.png":"https://patchwiki.biligame.com/images/nrc/8/87/qtl5c0vx64jr027gmnnh1za6g9erp2a.png","/map-media/15359d6e84c4cdfc5146.png":"https://patchwiki.biligame.com/images/nrc/2/20/9432cuk8ty4lewdygc1b7f0uho2k0nh.png","/map-media/6f1f480f59c0152c0473.png":"https://patchwiki.biligame.com/images/nrc/3/37/4wma1eal9ghtfh2fd84x9hx9jgf59qj.png","/map-media/aa1301ce3f9a22a8ae6d.png":"https://patchwiki.biligame.com/images/nrc/1/1e/b2kh8dvwgoltqz5da7rr2q8t13gpw6x.png","/map-media/38dedcf42fbb7471fbff.png":"https://patchwiki.biligame.com/images/nrc/0/09/hmanbzhtabqiecdc8j28g0p79hw6nxk.png","/map-media/39aa3f31277569d0af18.png":"https://patchwiki.biligame.com/images/nrc/7/76/hcpv2skl1gkgcelir9mwu18c4op3ftk.png","/map-media/b81916a0617d162eeee6.png":"https://patchwiki.biligame.com/images/nrc/c/cc/ch9lkfstusodxw26beehglb3qx86j8a.png","/map-media/e482281cdc27ecdc8ef5.png":"https://patchwiki.biligame.com/images/nrc/2/23/httk61k0eouk1kkbcjdrpuruom4zkjf.png","/map-media/2f5c07c5f7dbf5c6b67a.png":"https://patchwiki.biligame.com/images/nrc/1/19/25frqzyrl5a2g99o42qqll90pvd1h5v.png","/map-media/c33793ec2934bb08bd4e.png":"https://patchwiki.biligame.com/images/nrc/2/21/8o09b7gd5vo0b25ot4laiox7qxppwm7.png","/map-media/f957bf50912675a68d78.png":"https://patchwiki.biligame.com/images/nrc/b/bb/9bvei6gx4ps8twlwoiru49c8ph07mes.png","/map-media/5cf8741f515ebfa566ea.png":"https://patchwiki.biligame.com/images/nrc/8/84/os48mqeg91av9yzh888u7gyhqltqcfd.png","/map-media/f2beb68071535d5d7d89.png":"https://patchwiki.biligame.com/images/nrc/2/2c/40pegfq1d1xmzgzgtj89ndg3g95sm9o.png","/map-media/4f44f86bcca634ac3c4e.png":"https://patchwiki.biligame.com/images/nrc/a/a0/0eawq275o13dh7ux533cjzqtj8l281e.png","/map-media/8223f8870841103b4bfa.png":"https://patchwiki.biligame.com/images/nrc/2/26/aemz20243sfddu7blpljjvclwpqrmoj.png","/map-media/67e598deaa8c9e68f1df.png":"https://patchwiki.biligame.com/images/nrc/a/a6/58s1jwvfh7ud0r6tqhtv3fgflqjgiwm.png","/map-media/34119a54e11c3583749c.png":"https://patchwiki.biligame.com/images/nrc/6/69/0j15lme69z1nllspmgxw4f8h3eu8fpz.png","/map-media/c350c6aea76fc534eef3.png":"https://patchwiki.biligame.com/images/nrc/4/4e/lhvw88e8mwa5qqzmets0ycyu9wlh8pj.png","/map-media/b68a812e9d7eb4b49167.png":"https://patchwiki.biligame.com/images/nrc/3/3d/2amqo5zb960wkgjgewsccy1sy93upvh.png","/map-media/c6e693b3443fefe2081f.png":"https://patchwiki.biligame.com/images/nrc/b/bb/g1se51lda7akgzmgkqetgdrbpjfjeo6.png","/map-media/0832879fe31748864c33.png":"https://patchwiki.biligame.com/images/nrc/f/f6/7qmgoh2bwbtquusyur72mxkhh5w278z.png","/map-media/3b3028b3121dd5b5ef6e.png":"https://patchwiki.biligame.com/images/nrc/7/76/n0lkqxksayb7m3fh2zeukztw3u2v9xx.png","/map-media/dd3c5220eb8f117529d7.png":"https://patchwiki.biligame.com/images/nrc/1/12/f6zu6viaueke98fsabg0rpjjk6p9mdf.png","/map-media/1c72666689cbd17a68c9.png":"https://patchwiki.biligame.com/images/nrc/e/eb/npj5lr1yhslg32rcj56uk419zjumhoa.png","/map-media/e3560099905cd1fc4c3e.png":"https://patchwiki.biligame.com/images/nrc/8/8f/tg5c37wh27oij328z4zgbz1ezhlrj3y.png","/map-media/9139121f7f376aa4a0e3.png":"https://patchwiki.biligame.com/images/nrc/b/bc/b6carsvfl0t1yk6zie3qqq1ptov2eot.png","/map-media/ab3a6e32a9cdec73eb18.png":"https://patchwiki.biligame.com/images/nrc/e/ef/glytbe37k6q1g4a1xkdk923kqd3gday.png","/map-media/3ac09da69bbcf6c63bc8.png":"https://patchwiki.biligame.com/images/nrc/1/11/o7suj4dfl4vbyuea48d0r2z6lssjndx.png","/map-media/190f747700e4d0829d5d.png":"https://patchwiki.biligame.com/images/nrc/8/84/3czyerkzyrdyaymqhuy3ipogc9rgsbs.png","/map-media/992a4fd970e9cb9a2d79.png":"https://patchwiki.biligame.com/images/nrc/f/f7/3pqtz3vthxljvacresnfbx312rn3evz.png","/map-media/324329fc700079f35bca.png":"https://patchwiki.biligame.com/images/nrc/3/30/tdx47gnwyce4vyswfyo4fh9jksczn2o.png","/map-media/fdd1a8fdf8ab0d07359e.png":"https://patchwiki.biligame.com/images/nrc/e/ef/lirls4pvc0j3w0h9ph5ew3k4l2khyct.png","/map-media/7342617ed66c657c23ab.png":"https://patchwiki.biligame.com/images/nrc/1/18/150wiaj2gvh5z0ra9onqyukkj3f1lei.png","/map-media/1669ae4e70af7d9699c3.png":"https://patchwiki.biligame.com/images/nrc/f/fa/mzhjr9d0deh1zqczofvib72beeuc89t.png","/map-media/2e2141d0b9ce2a15749a.png":"https://patchwiki.biligame.com/images/nrc/c/c2/fclo5vujohlb0cdu29iafa55xsxay43.png","/map-media/88bea997d8c6f20d29c7.png":"https://patchwiki.biligame.com/images/nrc/6/63/l02b2q5inbkwqypx6bsvqbr2c9hmrbg.png","/map-media/11bdfe6112b13ca074d5.png":"https://patchwiki.biligame.com/images/nrc/c/c1/ny9f5obrp8l7unxzntxogzqee1g5sxr.png","/map-media/a05b26895f0866e5c427.png":"https://patchwiki.biligame.com/images/nrc/a/aa/nlw9y9jnh5l10rgr0jd0kxqxrypsjb4.png","/map-media/43287a87020cdd4be957.png":"https://patchwiki.biligame.com/images/nrc/a/a7/m5b3kmsh5d9j0ivfks33srb94rchzkd.png","/map-media/a2f4e4a55f7188bb466a.png":"https://patchwiki.biligame.com/images/nrc/0/0c/8lvhyz2mnhvfv9caoja7420pd6y3bof.png","/map-media/8d22a7061e36bd7c9853.png":"https://patchwiki.biligame.com/images/nrc/6/62/nlb4k1jy3a07yr3pvhp5qs18mrtl5ds.png","/map-media/ce4ff7d07613c6b63512.png":"https://patchwiki.biligame.com/images/nrc/8/8b/nlo8dqk6b5zx91z9zercahacgnw4syb.png","/map-media/021932388eda607d4d52.png":"https://patchwiki.biligame.com/images/nrc/0/03/hb4jsrsmwymzvv1m7q9ag5oiq58ibbp.png","/map-media/c35b4db04b1f8fa417ba.png":"https://patchwiki.biligame.com/images/nrc/3/37/reusd2iy3kcqihgry7j4g9d6oc3re13.png","/map-media/1730e21588f085f55840.png":"https://patchwiki.biligame.com/images/nrc/a/a5/027p24klvj2i61k6nq2d9aw7rdiobn5.png","/map-media/ed6a01ba37cf0a880793.png":"https://patchwiki.biligame.com/images/nrc/9/9f/h1428dlen25g5n765x6cfddkqgg9b9r.png","/map-media/f917c2f31bc851f46747.png":"https://patchwiki.biligame.com/images/nrc/5/5a/56abzp0589h7atcaqcq0iu33qloz219.png","/map-media/ab6d722d5d68d3f08478.png":"https://patchwiki.biligame.com/images/nrc/d/d5/0f1yk0kajilroijfqwu86t03y2577vv.png","/map-media/50aad10d8dbe4343c130.png":"https://patchwiki.biligame.com/images/nrc/a/a9/in3qh8b6ikl84zxpak794vulm93kowm.png","/map-media/402fe2c906da42a0dcfe.png":"https://patchwiki.biligame.com/images/nrc/f/fd/94w1d65wm5gu42tg2netpzqfn7yr46x.png","/map-media/5246eda480d8a1b8f59f.png":"https://patchwiki.biligame.com/images/nrc/9/9d/d0vtg0l97vc92m3md73ik7179e9elu8.png","/map-media/7c50ccc546224729ecfe.png":"https://patchwiki.biligame.com/images/nrc/3/32/6blu7jbojqp7y9iejjy3tl0yz4kxnuk.png","/map-media/f342191d989247787ca1.png":"https://patchwiki.biligame.com/images/nrc/d/df/p24dsk22myph5ng946yvjm3m3ldf6nj.png","/map-media/8e313e96d5448eee567b.png":"https://patchwiki.biligame.com/images/nrc/4/4e/6838xq40dc6bfzs7yus1npid2y7d04y.png","/map-media/12101b13371e793d9fac.png":"https://patchwiki.biligame.com/images/nrc/6/6f/29k7ldw3073ybz9qtenby76ptuhwv45.png","/map-media/982bb2e3f17808705891.png":"https://patchwiki.biligame.com/images/nrc/b/be/t3hl0dz9f5fnma70l58sgfak6tofqiv.png","/map-media/f33e3538792cbba16b2a.png":"https://patchwiki.biligame.com/images/nrc/e/e7/53gwqdrj888l1rz8fb2ehr1iu1019sy.png","/map-media/87ec61fa605e4eab5bb6.png":"https://patchwiki.biligame.com/images/nrc/4/46/l760byckr4zw85n7dz04c0h4z2t4hm6.png","/map-media/dff2ba1baed0e4cdb6ba.png":"https://patchwiki.biligame.com/images/nrc/1/1e/a362vqe6h7kzugahnjzjs30t79gftni.png","/map-media/8139c40dce5fb8658d5d.png":"https://patchwiki.biligame.com/images/nrc/0/07/9v7un6x7b7gt8qhw5v630yye8tglp5g.png","/map-media/c5d0ecb7650caaac78d9.png":"https://patchwiki.biligame.com/images/nrc/d/d1/bojzkps4rquomfze2e67pqk9aveyydd.png","/map-media/394557ad57ba269294fb.png":"https://patchwiki.biligame.com/images/nrc/e/e7/0uvgdetnli79s8w9ncrk9ap2dmpth86.png","/map-media/1cd5df57747ad0500af9.png":"https://patchwiki.biligame.com/images/nrc/9/96/4oyyfhw4q71q4u54xkrmzhsj7g4s2s1.png","/map-media/ed760785a1233dc08591.png":"https://patchwiki.biligame.com/images/nrc/1/10/blxvp7k90uq3p8prz24feerler3yfsi.png","/map-media/95c30caa811210ae3a03.png":"https://patchwiki.biligame.com/images/nrc/8/82/szjixvigfe1dpasr4ktv5pvoe1v7ivd.png","/map-media/d12b9495ed1592cc5e63.png":"https://patchwiki.biligame.com/images/nrc/3/37/hqyxlkyt4qkuup7xfrhjfokj0lj1k8o.png","/map-media/a172dbd9aedb15b3ca69.png":"https://patchwiki.biligame.com/images/nrc/b/bf/a6rstnbt287sb2o07tji8sk6uc1vye0.png","/map-media/5c3bba443f5f5fab75c4.png":"https://patchwiki.biligame.com/images/nrc/e/e1/k84x2fb4yfoeeuge6cuz93nvs1rm5vv.png","/map-media/88358abf88cc76b6a526.png":"https://patchwiki.biligame.com/images/nrc/d/d5/02q5821p47uv7xsalpi0ilqlffz56ux.png","/map-media/8574ada63e828d2fb4d0.png":"https://patchwiki.biligame.com/images/nrc/0/0d/2p0g7lhbx3s7segs3ckjk7fdlypum2k.png","/map-media/5141b394485175e62c1f.png":"https://patchwiki.biligame.com/images/nrc/9/9a/k0rw8027v2ynw6sjc8f8vgey9fj8r17.png","/map-media/066bdccecda9b1adfb4e.png":"https://patchwiki.biligame.com/images/nrc/d/d4/lfv6vnkpw1tvuhqugrlanfrbbq573pl.png","/map-media/2c42ba59da57c9dc26d1.png":"https://patchwiki.biligame.com/images/nrc/1/18/5g7enao6muwlau72bjiytvbcqb17stw.png","/map-media/eefeddd645491fbfb8c1.png":"https://patchwiki.biligame.com/images/nrc/5/5b/dsyp3qpgdb2b91qpqu85qjcm3r72tmt.png","/map-media/8ff6633bcb277a79213e.png":"https://patchwiki.biligame.com/images/nrc/6/64/il2pwdpruicjorzg4dgyfuef6ypicme.png","/map-media/806a11c4cc6bc02594e6.png":"https://patchwiki.biligame.com/images/nrc/2/23/03zz9mfit13dqbx1nt1w204pbljf4lb.png","/map-media/c4052635df65463bc2c9.png":"https://patchwiki.biligame.com/images/nrc/0/01/fs29skt4806pw0w95pe1136wt7f0160.png","/map-media/0af81038827c01175e7e.png":"https://patchwiki.biligame.com/images/nrc/7/7d/gxy3slkdy47gvtuv4be9uablp4x6p2w.png","/map-media/6b364a33a7bcc523caf3.png":"https://patchwiki.biligame.com/images/nrc/5/54/fhjhdva3klj6ltskhmxm6xt63v8hlu7.png","/map-media/eb34d8b8f6028884345e.png":"https://patchwiki.biligame.com/images/nrc/6/6f/i9wqjhogz2r6e00j0pcd8wtyvsz96tl.png","/map-media/8da938caeb5f5d8028ef.png":"https://patchwiki.biligame.com/images/nrc/8/85/81qh1rajlf56zhvywgr8rwlgq6bg539.png","/map-media/ef1a9e2ad05f12ee939e.png":"https://patchwiki.biligame.com/images/nrc/7/78/e6jjypyth8mtaubanq8ys0d18swa3wv.png","/map-media/6521d3ddf35b49f34899.png":"https://patchwiki.biligame.com/images/nrc/9/9a/8ok6x1whq5usbh4emuf6eekzkhpz5ls.png","/map-media/f1236dd85e757c8af911.png":"https://patchwiki.biligame.com/images/nrc/d/d1/sazy809r3uffdbww5pe9kw2kq7neiad.png","/map-media/f528e7a7d4eda6385ba4.png":"https://patchwiki.biligame.com/images/nrc/7/78/4xhfd6l1lz1xtv2j86zpfn0cdq3wh4i.png","/map-media/2848e937de85e925a834.png":"https://patchwiki.biligame.com/images/nrc/1/1d/sdtpuorwsbswaofndaosysgtopvqpnl.png","/map-media/74730f6da41b6be0425b.png":"https://patchwiki.biligame.com/images/nrc/e/e5/8igqswor6fp2laydx7t7myfnsrc3br3.png","/map-media/e3e30cff7037901aa2eb.png":"https://patchwiki.biligame.com/images/nrc/c/c1/c4c195qmuwi40bhpj2jf0heywwa0a97.png","/map-media/f5572b11bd87a2591444.png":"https://patchwiki.biligame.com/images/nrc/7/76/08ez2u5kk5b0bev023mygb6xnqbigj6.png","/map-media/528dc0c88da65dbb8baa.png":"https://patchwiki.biligame.com/images/nrc/a/a4/mwjittd5p6d5ninjzodveif9yfymjhl.png","/map-media/70296d27f60c4ca03ab6.png":"https://patchwiki.biligame.com/images/nrc/e/e9/qrej9y990ch0i5ty8zzwtz9i38e2ny5.png","/map-media/75491a96140d8571a006.png":"https://patchwiki.biligame.com/images/nrc/2/22/0id1k6gtvswzvnm3f7rvrq0t7oxtp78.png","/map-media/753c6a69b6a6f3d50e58.png":"https://patchwiki.biligame.com/images/nrc/6/6a/64wq0bnw715o94yuocs2gqfgt0imo4d.png","/map-media/074f53795974f7181926.png":"https://patchwiki.biligame.com/images/nrc/4/43/qmgp0m6s84i5623vf5v589jjmjuzre5.png","/map-media/74c04e0902f15bf95727.png":"https://patchwiki.biligame.com/images/nrc/b/b2/gz06zwugionobmi6ljjoucrmdd6gvi8.png","/map-media/e3eaed7ac8ed022066b6.png":"https://patchwiki.biligame.com/images/nrc/f/fe/ex98axedim41ozzze1x7x7lyyqakw7q.png","/map-media/765ed11f17de4cdf0356.png":"https://patchwiki.biligame.com/images/nrc/1/12/bezaa2sb5uvn6xag86i6cln0thujtx5.png","/map-media/69388d68f81518f74e3a.png":"https://patchwiki.biligame.com/images/nrc/d/db/2zun2gcvt1u5eb884qs03h1mk1puviw.png","/map-media/64c0357033c89bce4949.png":"https://patchwiki.biligame.com/images/nrc/2/21/lzuvmct9d9vg0ugkylmmlwt0q5qh4oz.png","/map-media/dd82b99008704c1cc435.png":"https://patchwiki.biligame.com/images/nrc/a/a5/s2pp9pgule37syl9oxo6eqo1cgbzf0c.png","/map-media/d01eb877edc34172a071.png":"https://patchwiki.biligame.com/images/nrc/f/f7/1dzslx1vf3uoql57ovnkhdzqbx66feg.png","/map-media/463e5546832f778d2949.png":"https://patchwiki.biligame.com/images/nrc/d/d2/bxetkjnh0jlaw9wfldoxsqlyokyi3da.png","/map-media/ef584a2d8f988005a2b4.png":"https://patchwiki.biligame.com/images/nrc/6/63/893a8zox1rcu2a9rcj4fqqgflcplg07.png","/map-media/ae20675daf7bdedaaeeb.png":"https://patchwiki.biligame.com/images/nrc/f/f7/jd0zioks95vusk4xmv2ig3fwjku6hs6.png","/map-media/e9a6d24a3e31afa1447c.png":"https://patchwiki.biligame.com/images/nrc/c/cf/rf6a08wgkomfr4gc2rf90lwbdj7xo85.png","/map-media/5d46c358ec58b3b48e98.png":"https://patchwiki.biligame.com/images/nrc/6/69/25usj9q75w7l4sp6tnk9n0x3yzyyt92.png","/map-media/084483d0fa15be0d52af.png":"https://patchwiki.biligame.com/images/nrc/f/f8/qkcf9t7cr43v78cupozgcrkz0xtyxbe.png","/map-media/1e5312acedd3a8975b44.png":"https://patchwiki.biligame.com/images/nrc/6/64/erm3umtkevhc7ewtc4pbe7mpa4u8l72.png","/map-media/418ef4e4dcbf0942f338.png":"https://patchwiki.biligame.com/images/nrc/c/cc/08mbn5hwxqy6nnsdmhlv1mdqsqsk6da.png","/map-media/5a0eeb384bf60f881c2b.png":"https://patchwiki.biligame.com/images/nrc/3/33/155mbvwk2n5am0jvcuiguup512fr40c.png","/map-media/0593792d28bf1582a2e1.png":"https://patchwiki.biligame.com/images/nrc/8/87/ftm2pvtveq3s840vd0edr0xyce8w4qo.png","/map-media/e3350be65907af5e1317.png":"https://patchwiki.biligame.com/images/nrc/5/59/8wkt7creidxeukqf0am23l1clcwxpe7.png","/map-media/4c721698dbc60f514f2e.png":"https://patchwiki.biligame.com/images/nrc/e/ec/etdf3jukptywryiy6koxplt8c2161vb.png","/map-media/f708fc226038cb1f0554.png":"https://patchwiki.biligame.com/images/nrc/6/66/2t5o367rjdlkb5r85ej8kpn125zgq31.png","/map-media/0f9c19e79e7248ef19d9.png":"https://patchwiki.biligame.com/images/nrc/d/d6/kw10zjem470y7975x4835lndl1czmrh.png","/map-media/a3593ac2023638beeaf0.png":"https://patchwiki.biligame.com/images/nrc/6/6d/8giffvagkgrjzookmlwz4uchagz7ari.png","/map-media/ba9c2275dc62fe699868.png":"https://patchwiki.biligame.com/images/nrc/e/ea/74kwn2mn2vggp8wk1p96nz51q96zbam.png","/map-media/6c693d106a02d847a6d8.png":"https://patchwiki.biligame.com/images/nrc/5/53/0fvm7k7u890izyv7goojx0etiijxwhb.png","/map-media/6f5a8c74b73f4c832ec1.png":"https://patchwiki.biligame.com/images/nrc/8/8e/nv54m7un1mzxlzysjky8lzmnixhyg09.png","/map-media/0b0c45e50da37aeba01c.png":"https://patchwiki.biligame.com/images/nrc/0/0c/85ipj3idqpgoufybgnkhlh4usa2ian8.png","/map-media/8715bf70a1d6deebc449.png":"https://patchwiki.biligame.com/images/nrc/d/d9/760mlwaaofx6i1zt4k2cao17iqd482a.png","/map-media/070e95e99f54343540cf.png":"https://patchwiki.biligame.com/images/nrc/e/ed/dk7dv9unnk1ykza6kmlhv6pq0b44rgo.png","/map-media/a97c4afd98e90ef6fa0d.png":"https://patchwiki.biligame.com/images/nrc/e/e1/7o5jgg97us0zaj8oaqo7yj81crdd49c.png","/map-media/ca0b953b53ef2cf61358.png":"https://patchwiki.biligame.com/images/nrc/4/48/nt3qbjxex380extz4jtxygzdh57x7ph.png","/map-media/5b1dc1777d6810142d41.png":"https://patchwiki.biligame.com/images/nrc/d/dc/chj2orcp3dhh99opzzm2jmr5gvjyk5y.png","/map-media/25cabf84ef5c0d131866.png":"https://patchwiki.biligame.com/images/nrc/1/1c/krlb78cq77lhso45pk84zy1n98vmjbi.png","/map-media/a395b5ea69a7d8450038.png":"https://patchwiki.biligame.com/images/nrc/6/6d/avcwojsbfgtnhb70elud2hh1ciujwiy.png","/map-media/658e8a4f03acae3e9e33.png":"https://patchwiki.biligame.com/images/nrc/b/bd/sx6wzqna1xlif5o9c33zjagdb0rcu4h.png","/map-media/93f6e6cca7bd4771a97b.png":"https://patchwiki.biligame.com/images/nrc/2/2c/53zjmgdesu2kil2379erck6qrz6h5d8.png","/map-media/ba14ecc373c60373fb73.png":"https://patchwiki.biligame.com/images/nrc/3/3b/lrhu7jiy9jmb05dx9ltnpk8049iwkzj.png","/map-media/981f9c6123e31431d5d0.png":"https://patchwiki.biligame.com/images/nrc/4/47/9c10pr4nasn0wg1ux2ejdonfzpis9ux.png","/map-media/2f1c6bd8b582226fd3c4.png":"https://patchwiki.biligame.com/images/nrc/9/9d/e71igy0ooxhvb4ggz13k4gry8usa0qc.png","/map-media/dcab6678faedbff1114b.png":"https://patchwiki.biligame.com/images/nrc/7/7e/9bm8rk66i52ugcfam4hg8xce4dr6lq7.png","/map-media/a0d4b39a811a04682bb5.png":"https://patchwiki.biligame.com/images/nrc/e/ee/cqpqt3ols95505nxz3ho4mag5esbube.png","/map-media/290497f9ba062a6facb0.png":"https://patchwiki.biligame.com/images/nrc/d/dc/8f4u2yy5gjkqtxljk4xhi7sro9ipuh8.png","/map-media/c87478ab35b3bfe381bf.png":"https://patchwiki.biligame.com/images/nrc/f/fa/5x0fbcxkjah3cr29o9jtxnwi0pexkna.png","/map-media/17921b23ac8f3ec0c868.png":"https://patchwiki.biligame.com/images/nrc/7/7e/k7hwt8709kj8sh8k4em40t96ea909qd.png","/map-media/6913eae4efa255891058.png":"https://patchwiki.biligame.com/images/nrc/4/40/ov5jl5fqkmp45vj3fauw1l3ej5sl65x.png","/map-media/cd8e2eda7c9aefc66128.png":"https://patchwiki.biligame.com/images/nrc/3/3c/f9se9vz5n2btbssusby8p8v163okuw3.png","/map-media/0a1e4ecac1a2560986f2.png":"https://patchwiki.biligame.com/images/nrc/3/30/djf7vaw7zda92gj4ni8iu6mlb9qj8cu.png","/map-media/43dbfb2d63d5468f1633.png":"https://patchwiki.biligame.com/images/nrc/d/d6/i2gzmegaku2wojihxm61vaytugthoa0.png","/map-media/16ff916edc86cbd059ea.png":"https://patchwiki.biligame.com/images/nrc/3/3b/i24iedtg3za83hphxpyb8q6nawuyqtk.png","/map-media/b090d8fb3d01c6e5b086.png":"https://patchwiki.biligame.com/images/nrc/6/63/qefkkerhp6pzms5l1ap1uuiysxewhxi.png","/map-media/2f90475558b82e2f126d.png":"https://patchwiki.biligame.com/images/nrc/a/ad/gid9u873h80052j9tzkdwkyfyls0wc5.png","/map-media/19b273b930ca6c08a40e.png":"https://patchwiki.biligame.com/images/nrc/b/b5/h37vhowtelabw830dopgqohkrlkggdd.png","/map-media/f727fffc4a1aca6557d2.png":"https://patchwiki.biligame.com/images/nrc/4/4f/0vgcjoybual88hba51jv53bagoz3ghx.png","/map-media/853e10013a10abff0fb0.png":"https://patchwiki.biligame.com/images/nrc/7/79/jamb4peczwd13jcw15my70k9jx5j2ah.png","/map-media/e540fad0606c08c9f3f4.png":"https://patchwiki.biligame.com/images/nrc/7/7d/3t8t0e7rl6a68ep03i2c5v1bclvkqz4.png","/map-media/a44bca8b2a30d579783c.png":"https://patchwiki.biligame.com/images/nrc/7/7f/11v95p021ghct9mbi6p371fh5uj555w.png","/map-media/505ddad3ef58ab88bfea.png":"https://patchwiki.biligame.com/images/nrc/6/63/j301k2kntl19hgh44hdgff8xag6thih.png","/map-media/72cfd961ceec3b9caee0.png":"https://patchwiki.biligame.com/images/nrc/6/61/ifbkjbkm8v9c4mx2tp4ftcsss8f2nx6.png","/map-media/ebf7b8570d03d30c68ab.png":"https://patchwiki.biligame.com/images/nrc/3/33/9p9d14cdv1py3hv5nf2k2trfcv9l4yj.png","/map-media/0c49483b90ad13fea8ee.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ob3v0ool89bniewxrzr2n4jjhi74gyy.png","/map-media/9cb1e4aef5001c16b4e4.png":"https://patchwiki.biligame.com/images/nrc/3/36/0uzvneoorlq7crjof3dkyzn3qm7vs46.png","/map-media/85bb8edcbcd8a85ca1e1.png":"https://patchwiki.biligame.com/images/nrc/b/bf/mj8yoriame5afz78lxtpvz3l6bry2g9.png","/map-media/ff6674194fcae3248c69.png":"https://patchwiki.biligame.com/images/nrc/6/61/kdgtidyk0xjzo9arjj4olhanxp7m9kt.png","/map-media/22e0cf9aa3a4bfd3853f.png":"https://patchwiki.biligame.com/images/nrc/a/ad/am97j9ap2kkd48gjm0lyitdy4w69xx5.png","/map-media/502e77a1a3074f3aa673.png":"https://patchwiki.biligame.com/images/nrc/7/71/4h4prbdww8j6sf11tgds9mm9l9ewikc.png","/map-media/ac2d1342951362a0fa8d.png":"https://patchwiki.biligame.com/images/nrc/c/cf/hbz442o16fi1wbp9tksc51aim6fedid.png","/map-media/0ae6ee609791473eea74.png":"https://patchwiki.biligame.com/images/nrc/9/9a/o2jphuc3ugf3k8zjn9w9xzb94cmbxmg.png","/map-media/04af18a38daf2193e99f.png":"https://patchwiki.biligame.com/images/nrc/d/d9/0aawsrwx4m8uqehibipzpwy03xfj0ep.png","/map-media/34b72decd292a6096e64.png":"https://patchwiki.biligame.com/images/nrc/f/fa/n281j2uzmwnlyz2su55q8dxl4i4xrfn.png","/map-media/473897f876efd30801cf.png":"https://patchwiki.biligame.com/images/nrc/f/f2/a72wi1o2ht237f3kfjpm3l5b6mn7vrf.png","/map-media/aaae83ebe95c0be9558e.png":"https://patchwiki.biligame.com/images/nrc/7/7a/b1qxyr1fvbxlz0diwic343qoj69hp1j.png","/map-media/02b10b0b41c805d33c42.png":"https://patchwiki.biligame.com/images/nrc/d/d8/50g8hv31admke6cpq4kx0zokp8x65n9.png","/map-media/b9d1ee7e63585fe273f0.png":"https://patchwiki.biligame.com/images/nrc/a/a0/c6ritp7erjxx24hyal6ifklb6561izu.png","/map-media/07eb10f0d0a2c8471c14.png":"https://patchwiki.biligame.com/images/nrc/6/68/q77yibxdkmc65a7e9dj5hffmrnubl83.png","/map-media/8d75ea3869a9ed5d28c1.png":"https://patchwiki.biligame.com/images/nrc/1/1e/lziv902uuqykuuwm0te0wdjkgw6og2y.png","/map-media/807d3e927e142963d556.png":"https://patchwiki.biligame.com/images/nrc/9/9b/5iw95djqajk4nq8vnddguuip3qezyq6.png","/map-media/d71006058483c1afbb58.png":"https://patchwiki.biligame.com/images/nrc/4/43/grjjhizxdgou0q8a1klqxwcf989fh18.png","/map-media/4b2314a29c1a8841dda9.png":"https://patchwiki.biligame.com/images/nrc/b/b6/lsaml3sej0z3p9ttrqhj71b713yes06.png","/map-media/4ffe857fdabc736cc621.png":"https://patchwiki.biligame.com/images/nrc/9/95/2km6k9e6olc8t7a5ui54ilo92lmo6pk.png","/map-media/b9c21ce735b4d6308db0.png":"https://patchwiki.biligame.com/images/nrc/6/69/li22rzo4m3qhisnqa4b0x3cecsalpmw.png","/map-media/3ba0fb84b11170b78997.png":"https://patchwiki.biligame.com/images/nrc/a/ab/1bz9ao7j7bpw8qe6qctu46zaqdoatap.png","/map-media/5680602bba40dbe893bd.png":"https://patchwiki.biligame.com/images/nrc/9/99/5ao5kgodkvgkj4d7q470halfjgdym9n.png","/map-media/a31bb31f13bea93bba29.png":"https://patchwiki.biligame.com/images/nrc/e/ed/bwls08k0tb0fg8dks0fgdulxpefqsqe.png","/map-media/9d5321e7f06aac941283.png":"https://patchwiki.biligame.com/images/nrc/9/9b/3be76m0vk4bp0zb8ytjd81brcficu5m.png","/map-media/8e12f70fda74460c862c.png":"https://patchwiki.biligame.com/images/nrc/2/23/fwcm5o3fsecqhqzfgmyx1ibk9ox704q.png","/map-media/79e97ff76b7c15dcf3a6.png":"https://patchwiki.biligame.com/images/nrc/b/b8/3jggyswhvn5gnrlq61hqgkzlaymaqfb.png","/map-media/8d77279741f8adfdda91.png":"https://patchwiki.biligame.com/images/nrc/3/33/pkwmi9kjf4yu1xvaq8ax1mtcdsbdqnm.png","/map-media/446e77b39912057a8c17.png":"https://patchwiki.biligame.com/images/nrc/3/32/8sam16rx38g9ls3fj1o5op6vlab707s.png","/map-media/445dcebfe22fad63e531.png":"https://patchwiki.biligame.com/images/nrc/d/d9/dnorh7t7vny6cpokfny9csdg8lbstth.png","/map-media/8a5fee9a64ebce3694b1.png":"https://patchwiki.biligame.com/images/nrc/c/ca/8dfu46jkvg9v4jg0yxc24pw3gj1dlx6.png","/map-media/d9312024bf7853fc6754.png":"https://patchwiki.biligame.com/images/nrc/d/d5/fq22wzroexqqj4jml3tjo2794e2tsdt.png","/map-media/1a807adad85a18bd0030.png":"https://patchwiki.biligame.com/images/nrc/c/c9/5g5ylk7dkmu4fogkvtqklppt37g2zgo.png","/map-media/b56cc5ce3ce70c7360bc.png":"https://patchwiki.biligame.com/images/nrc/f/f1/nogj5xypdzf5ulh5xty7hhywf8551ij.png","/map-media/0a89b68f89f3ddef38b6.png":"https://patchwiki.biligame.com/images/nrc/4/4a/b7ut50h5lrq3kwf0lwabjomhmqp1sn3.png","/map-media/5045493aac8257751100.png":"https://patchwiki.biligame.com/images/nrc/7/7e/1qpy3yyhl5z5bxaiqxicwujsn7ilp5y.png","/map-media/2647cc96c92c0589b046.png":"https://patchwiki.biligame.com/images/nrc/e/ec/rta7roxxms33qxy8heqzwvf4jck36xm.png","/map-media/fce20fbd8db40a670f0a.png":"https://patchwiki.biligame.com/images/nrc/f/fc/80adsiwiparkk0sswtbghk5rzzw35tj.png","/map-media/0994a75a577836369d41.png":"https://patchwiki.biligame.com/images/nrc/3/31/7a1apzbp4hrxsef3xafqloir0nrmsul.png","/map-media/e0d11adb9d984dbc7871.png":"https://patchwiki.biligame.com/images/nrc/2/2d/rrjou0s1qj92wh4axm9p1xhjnp63l7m.png","/map-media/f7eea2da49f3527b0b5b.png":"https://patchwiki.biligame.com/images/nrc/c/cf/livn8spknbb7uybt62tsek2waznh6ro.png","/map-media/cbcb50580350b740bfcc.png":"https://patchwiki.biligame.com/images/nrc/a/ad/ola6v40xrh94g7c0cquoks3p0k9iwy7.png","/map-media/7ce9d30fba9ba3a5a727.png":"https://patchwiki.biligame.com/images/nrc/a/a6/61cbf12txdi2n0an7frispzmc9l7vxt.png","/map-media/2d076844163568a576ae.png":"https://patchwiki.biligame.com/images/nrc/7/75/t6j3sdy2cqkwm3hqk27zx2v1f3o9ajk.png","/map-media/9ddf803a18f42492a3f0.png":"https://patchwiki.biligame.com/images/nrc/7/7e/67ri7bn6edtuxfb2kc033wa35o3nae2.png","/map-media/810682b1656704296a76.png":"https://patchwiki.biligame.com/images/nrc/9/92/7ntinrl7os593duhj9s5gyrnr0sah02.png","/map-media/d84d3ce449e902f498f7.png":"https://patchwiki.biligame.com/images/nrc/5/55/q7qs049p2vlou9q5syth2cvp8v6qd8o.png","/map-media/f136e780647ba8e8388c.png":"https://patchwiki.biligame.com/images/nrc/6/6b/lrq04ua91m01t52hheq566m5ie6dve9.png","/map-media/70d5ade18c7bf9a095c1.png":"https://patchwiki.biligame.com/images/nrc/d/dd/d6h7avecgeosae52sutcv8v3cee1vnr.png","/map-media/6a17aa12a08d2bc5881a.png":"https://patchwiki.biligame.com/images/nrc/8/89/5rwfqnha21sbnuge3ch7ot7furthkg0.png","/map-media/db80a801a6223273dda3.png":"https://patchwiki.biligame.com/images/nrc/7/7f/0nhhmm5k5o2fetmni71az04rws6ypx1.png","/map-media/23949bc831a221f780f4.png":"https://patchwiki.biligame.com/images/nrc/4/40/ioysc4p654ywpwjfr907c7etzn9smru.png","/map-media/3034286bd0cf38848ec2.png":"https://patchwiki.biligame.com/images/nrc/c/c8/3u85rmc4cju1o2dc5zxprcw1ypwsvwb.png","/map-media/4db4be7aac8ba73283d0.png":"https://patchwiki.biligame.com/images/nrc/8/89/fa0ps1mgbnm93p5hbhfrfqr3qbx7bjj.png","/map-media/f3bb9e444c9ad817f967.png":"https://patchwiki.biligame.com/images/nrc/8/82/s0n1ou2eknegmvf38r6zwrw0jb8vzeu.png","/map-media/a93e8c370142960e152b.png":"https://patchwiki.biligame.com/images/nrc/c/c3/oqudf97c1al3jz8dacyhnvkngh0kg68.png","/map-media/7c93a83bec81ffae8a7c.png":"https://patchwiki.biligame.com/images/nrc/d/d0/7lnt96tlhbzhagpeqnsg8c6gvv2z1n4.png","/map-media/3af9623387e2f7096da2.png":"https://patchwiki.biligame.com/images/nrc/3/30/2z3x1ao5dz6bpobtoisbz2jatfjowu9.png","/map-media/0fd37b4eb2483f08ac1b.png":"https://patchwiki.biligame.com/images/nrc/7/71/r7q3nhlpa3dxglvhrqt8fzok2c8cxc2.png","/map-media/1b49253865368c423c3d.png":"https://patchwiki.biligame.com/images/nrc/d/d6/0fty64b3jsr01p30b3ln7eprk4qakhb.png","/map-media/3ba388134ce9da5497c4.png":"https://patchwiki.biligame.com/images/nrc/3/30/6tocz9wac8ok6y0n031gaquyc29l2b1.png","/map-media/a1a1d98146ae91f4ef0c.png":"https://patchwiki.biligame.com/images/nrc/b/bf/4aosttgwgbcucwt23k6vmr18jok4i74.png","/map-media/9314133331b44870c9b4.png":"https://patchwiki.biligame.com/images/nrc/e/e5/jagyz1zu7h7ytqcz01og5fpebjd5ily.png","/map-media/44ce98f51f6e1193b947.png":"https://patchwiki.biligame.com/images/nrc/b/b1/ip39fq9tjginvsvdj46ifr5rq1h2onv.png","/map-media/d2f324bea53cdfb5d6b8.png":"https://patchwiki.biligame.com/images/nrc/9/9c/tm6rhng3mi262cxuuvkqc6ycwhd5f7w.png","/map-media/923db95619a42e994282.png":"https://patchwiki.biligame.com/images/nrc/5/51/ammoyl8h4sld93ssdocrkj87rqa4nr0.png","/map-media/7345550e313ac8c48900.png":"https://patchwiki.biligame.com/images/nrc/8/80/i71wucgffqz4dququqrq3rbp40a4zw1.png","/map-media/89bf681dd706448848c4.png":"https://patchwiki.biligame.com/images/nrc/e/e2/gx4ir9143dyyj1oq5zl21trymhcjcfa.png","/map-media/d1a2e8463197c88766d3.png":"https://patchwiki.biligame.com/images/nrc/f/f4/1vq7qpaz0l1cquarz86v0dk1medgo2d.png","/map-media/eedffca414f71baae9fb.png":"https://patchwiki.biligame.com/images/nrc/8/83/hrgqog0z8tqe8uuzoo1j7v4tkifkvp4.png","/map-media/316752a64954152add67.png":"https://patchwiki.biligame.com/images/nrc/6/6d/d3eitw1vhui91kag55sgr5k1ypbbi0f.png","/map-media/be3d1e099381f0920502.png":"https://patchwiki.biligame.com/images/nrc/3/32/d3q2pcwbuzw2zc0ksfrm3ppr2sv21lk.png","/map-media/824e28e7292108cecc6d.png":"https://patchwiki.biligame.com/images/nrc/e/e3/ove4fojl398j4rckkuvgsjbedc31lc3.png","/map-media/18828f21c14ba3378c80.png":"https://patchwiki.biligame.com/images/nrc/2/27/1gzzq1l0ibx1i7uoikftq32savhahxu.png","/map-media/5fbc2aea0bc41a86abc2.png":"https://patchwiki.biligame.com/images/nrc/f/f0/6v356huadfgb3sdxtdqwkt0mf2t7ll8.png","/map-media/6790628685a9537f8f74.png":"https://patchwiki.biligame.com/images/nrc/5/52/8qyouu515ak5wdm2edxulzes144p1wf.png","/map-media/60047e111d267711a79a.png":"https://patchwiki.biligame.com/images/nrc/4/4c/fl742n9hlnxlmx2kchksr9wndu5k4z6.png","/map-media/1110ecc038c3e8a6977c.png":"https://patchwiki.biligame.com/images/nrc/7/73/owx1vakv2e54esqn3mvzx2jc9iz3wpx.png","/map-media/ee72917103b81b245cb3.png":"https://patchwiki.biligame.com/images/nrc/0/0c/7jaisggn2sbgy70b579rq4s414el17p.png","/map-media/d3f1173be4a1fe642032.png":"https://patchwiki.biligame.com/images/nrc/1/13/scfg4e7dzomkdwmknwtcvom057jygj5.png","/map-media/17511911289f6f3e7964.png":"https://patchwiki.biligame.com/images/nrc/f/f0/88gu85nodrfgfl474m7d2m3jrj46llm.png","/map-media/df6e9f748003fe9ade35.png":"https://patchwiki.biligame.com/images/nrc/2/27/4y22x8j73duvh3lzfy22r73o3cszngn.png","/map-media/e593e3de7c6bef6d1a47.png":"https://patchwiki.biligame.com/images/nrc/d/dd/00uy91stjiupfqde42qcwl00a75pp5t.png","/map-media/8d58c465700f5efd0de4.png":"https://patchwiki.biligame.com/images/nrc/1/19/281juhb6sa9fynf9t1gkiqh3pgq42dh.png","/map-media/0334ac9d1d3e1f234501.png":"https://patchwiki.biligame.com/images/nrc/1/1c/7h1gaton7492p31iue9xcbnp33org1w.png","/map-media/93fc9156d1bac9cafc7c.png":"https://patchwiki.biligame.com/images/nrc/e/ed/agt81hesyan0yyqnp8g13ap4gqtrk9h.png","/map-media/f5710849a52699c93c1f.png":"https://patchwiki.biligame.com/images/nrc/6/6f/0zj1foa249qh644x8l83bijzw4vg81y.png","/map-media/1ed2882d58e7783a1222.png":"https://patchwiki.biligame.com/images/nrc/5/51/0jfcorsg8aiylgt06a7vr3bwmpa1xd6.png","/map-media/3f69fb397e1904689c41.png":"https://patchwiki.biligame.com/images/nrc/9/97/4lv8awraz9myf3z0onugxy0hu7jqh3i.png","/map-media/6605ae3584a0d270b8d7.png":"https://patchwiki.biligame.com/images/nrc/9/96/foxrdvko6wnjwhso59mnrnaa4x11i0r.png","/map-media/150811607b57917bc541.png":"https://patchwiki.biligame.com/images/nrc/b/bd/dx1klpi8j618eb0w1e0vewys60gnum9.png","/map-media/f1873128adc3a42ded22.png":"https://patchwiki.biligame.com/images/nrc/c/c7/avmzmh5j4vorbk323bu7etsccxojgpc.png","/map-media/c1f41a7d697c05c49ff9.png":"https://patchwiki.biligame.com/images/nrc/b/b5/orift80se7bb3j7i7ry8azzwgsgq73a.png","/map-media/04c304c27a03b5a655a3.png":"https://patchwiki.biligame.com/images/nrc/2/22/7um92jfe644f8l6642389twg3y95555.png","/map-media/59ef8db0e4ce2e072f1b.png":"https://patchwiki.biligame.com/images/nrc/3/36/4v6sqik93xzr6q58dvcri2z1qtkl07w.png","/map-media/ee12cc4e40e57e3b66d1.png":"https://patchwiki.biligame.com/images/nrc/d/d5/a8j91qxzryqq34c0grz04qxakq798hi.png","/map-media/eaa7f4d1b68f7c42cb2b.png":"https://patchwiki.biligame.com/images/nrc/3/3e/0bp18yuvkmk2z3tb0nlijdq7wb6lu2b.png","/map-media/643816963990c49d1033.png":"https://patchwiki.biligame.com/images/nrc/a/a0/3bc8fk88e2qyjrl5zwxcoh36zqonvtp.png","/map-media/78444b3df06ccd2503d9.png":"https://patchwiki.biligame.com/images/nrc/6/6a/q8snud48y5zyxbvlfosq0delcy06dap.png","/map-media/3403afa1640079744317.png":"https://patchwiki.biligame.com/images/nrc/6/6f/qy6jo735usmsq31os16libzudws80xb.png","/map-media/3263e2407564894efb01.png":"https://patchwiki.biligame.com/images/nrc/c/cd/aufnmn3ei3kqe7nhodcujvc3xj7i0zn.png","/map-media/75a0df20b8ed5bd2fbc7.png":"https://patchwiki.biligame.com/images/nrc/4/42/lcifcec0q8bcpzxn5iqjhs0597giite.png","/map-media/3942fcf0f1adfa734b40.png":"https://patchwiki.biligame.com/images/nrc/0/0f/snsq6kuhu0vcnartruradtcm0k59d75.png","/map-media/39bb8870912cb937f427.png":"https://patchwiki.biligame.com/images/nrc/b/b8/n71sn0pop2y8t1wosqey5w27khiaija.png","/map-media/559e4f5da02496e65bd7.png":"https://patchwiki.biligame.com/images/nrc/e/ec/som252qbbyqk7jcem1rjrntfpzous0f.png","/map-media/aefe5b8f8b7c0cff3a36.png":"https://patchwiki.biligame.com/images/nrc/b/b0/dokbzd2j0gr52qqyhndifhba66tlfw3.png","/map-media/50e20039edb19ea516cc.png":"https://patchwiki.biligame.com/images/nrc/b/b5/ptnykvqlsknwg8kuxqyd2ay7m0qa2dd.png","/map-media/7f7260172cb6094568ab.png":"https://patchwiki.biligame.com/images/nrc/2/27/lqydk9w7moo1yujrj0th8vbycq4k4xd.png","/map-media/57783b8c8d1caa1d1645.png":"https://patchwiki.biligame.com/images/nrc/b/b4/f9pqlcizng4n4kkkz36dm92v3rkj57s.png","/map-media/205a91fd03102515d6f4.png":"https://patchwiki.biligame.com/images/nrc/a/a9/ql6qg3vz0qqfhuyqg3ulyodvhfmm03i.png","/map-media/368a2fb387854d1aa3fa.png":"https://patchwiki.biligame.com/images/nrc/9/9b/rpvmorqdb045j4190b6hywun8706hiq.png","/map-media/b91190be29fe28ea51bf.png":"https://patchwiki.biligame.com/images/nrc/3/35/h46scsxl06b8miqa4d9tkahis33ek5q.png","/map-media/f5cd601f53a9b7e2afd5.png":"https://patchwiki.biligame.com/images/nrc/e/ee/5cb1969sdl133cxcso97wgkw7bkxc8i.png","/map-media/f513b343fa2702874682.png":"https://patchwiki.biligame.com/images/nrc/8/8f/189nus4oj2xqh48rqwhgh4dhm0kiipn.png","/map-media/f55bc9ec3bcc9eb11dd0.png":"https://patchwiki.biligame.com/images/nrc/8/89/kgz33yztwxzcay6tqakvw6z4i3erw7t.png","/map-media/162a7bfb49e811cbf181.png":"https://patchwiki.biligame.com/images/nrc/2/21/bu0zna5dig7brc6k1mqo7c969kiflpv.png","/map-media/9aaa554f1d0a9e76b1e5.png":"https://patchwiki.biligame.com/images/nrc/8/8d/r8c50d94hqqjy9tsh448itx5aimsy6l.png","/map-media/6c7cdc2bf1b4a74d3a14.png":"https://patchwiki.biligame.com/images/nrc/7/7b/l6szwdbfz6nl67ibzo0h9sqds9gqs69.png","/map-media/facc3847f565b4764807.png":"https://patchwiki.biligame.com/images/nrc/5/56/js6iyg1ipetag668wn7a36a8tnt6oz4.png","/map-media/a9a32b0291dd5a976dc6.png":"https://patchwiki.biligame.com/images/nrc/7/76/kvoe7nzcyjq75mnxvw4ov30k90wdd2y.png","/map-media/94b079fd285d1da65797.png":"https://patchwiki.biligame.com/images/nrc/3/37/hqyxlkyt4qkuup7xfrhjfokj0lj1k8o.png","/map-media/9516ec53cd5ed14efa37.png":"https://patchwiki.biligame.com/images/nrc/4/45/3ac60xumsgwuup7qecpv3oqe0x01w0w.png","/map-media/00544a603f9758dae137.png":"https://patchwiki.biligame.com/images/nrc/e/e0/4oa3u9z2vnkvrksvb9ymc3c79561ll2.png","/map-media/79798c419c7a9ec80a32.png":"https://patchwiki.biligame.com/images/nrc/f/f6/b6ya21kgbtifwo6w8w13j4r99g8gvqn.png","/map-media/5f4ec3a5dcadac062b7b.png":"https://patchwiki.biligame.com/images/nrc/0/0d/2544qwqy61qbiy35lqc1ztl6ftkqoa7.png","/map-media/924ff6fdf67a6d488b88.png":"https://patchwiki.biligame.com/images/nrc/e/ea/lweofmp6z4d83y0swgpp08sxhlnu6j0.png","/map-media/0847fb3b73649bc87407.png":"https://patchwiki.biligame.com/images/nrc/d/de/qgtzh9g54t0ife6ckc4pdog7xo4eoj1.png","/map-media/9a758907e12992cf6e86.png":"https://patchwiki.biligame.com/images/nrc/d/de/qgtzh9g54t0ife6ckc4pdog7xo4eoj1.png","/map-media/03bd46d91e68a3bb82c1.png":"https://patchwiki.biligame.com/images/nrc/d/de/qgtzh9g54t0ife6ckc4pdog7xo4eoj1.png","/map-media/af4665a14e463560b460.png":"https://patchwiki.biligame.com/images/nrc/d/de/qgtzh9g54t0ife6ckc4pdog7xo4eoj1.png","/map-media/e4551bd2a23b914a15a0.png":"https://patchwiki.biligame.com/images/nrc/a/a2/t8av6bubnfrx1a5uo61qrc6ttih7mrz.png","/map-media/5f3297a0c01361e9bf9a.png":"https://patchwiki.biligame.com/images/nrc/8/89/lqg681055pag391jw25djmjp67zghia.png","/map-media/2e7ff96efed739812b2b.png":"https://patchwiki.biligame.com/images/nrc/9/9b/ci9ckmikskbibxzdbkuroi2o848j2f7.png","/map-media/c0c0a15d411738066ff5.png":"https://patchwiki.biligame.com/images/nrc/7/7e/dhddrzvnjbol7loc3fxadg2c5q4nuit.png","/map-media/615408bc92e25590b8c5.png":"https://patchwiki.biligame.com/images/nrc/7/7b/lqal30isazo5dcuummpe1vppbuscbom.png","/map-media/997e881e430faab04020.png":"https://patchwiki.biligame.com/images/nrc/7/7e/dhddrzvnjbol7loc3fxadg2c5q4nuit.png","/map-media/bf6fdcec4bc74317c7d5.png":"https://patchwiki.biligame.com/images/nrc/7/7e/dhddrzvnjbol7loc3fxadg2c5q4nuit.png","/map-media/c5a93b378275890fda43.png":"https://patchwiki.biligame.com/images/nrc/7/7e/dhddrzvnjbol7loc3fxadg2c5q4nuit.png","/map-media/316a9bd7d3022000d344.png":"https://patchwiki.biligame.com/images/nrc/7/78/la2op2bp2ttc5x9t5sdmpwrb2sc2mbc.png","/map-media/2de34af7c1929795bbd9.png":"https://patchwiki.biligame.com/images/nrc/f/fb/dqn7jri59b0jceh9ol83mr64l7l4ll5.png","/map-media/1a538536bd074a4000f6.png":"https://patchwiki.biligame.com/images/nrc/0/0e/48n6b17uunr6y4x6vaeqnr1wtrn8fd4.png","/map-media/98b62cad1c4be2f4be65.png":"https://patchwiki.biligame.com/images/nrc/e/e0/r34yrisscwknqvxa4a6uq0y4kjbmt82.png","/map-media/665fed9eae2fd4ad218d.png":"https://patchwiki.biligame.com/images/nrc/3/37/7syuwarr3czty0ezt0iqptvgyhb9dju.png","/map-media/8f28756cf23422637067.png":"https://patchwiki.biligame.com/images/nrc/e/e2/ofxuuen768ej809y3a6zoss9jmx1jd8.png","/map-media/8fa84c2d7850a3802fcd.png":"https://patchwiki.biligame.com/images/nrc/c/cb/p0ixlaw09ltuo1eebf9g9gau9m6q9co.png","/map-media/77701cd5c07599084391.png":"https://patchwiki.biligame.com/images/nrc/e/e2/idrepxsbazvhvqxiepathjkcauy58jv.png","/map-media/2e8e93aefce35e992800.png":"https://patchwiki.biligame.com/images/nrc/6/64/m1zayrrjfmg66hhpad2yymo63id0soy.png","/map-media/19cf6d6a5bc0b7586391.png":"https://patchwiki.biligame.com/images/nrc/2/27/5m6ewjgnim203z19zz7kfy06eqejgn9.png","/map-media/89fcbcbae48cc0dcb13c.png":"https://patchwiki.biligame.com/images/nrc/5/50/m2e4w1aq2cvv3zfmdfdawo6zcmvxmsf.png","/map-media/c5aa3559c63d1fe48146.png":"https://patchwiki.biligame.com/images/nrc/c/cb/bkgo7i5ei82iy1x2cvlu1vthsptp81b.png","/map-media/21f1d3327cabb18e3aae.png":"https://patchwiki.biligame.com/images/nrc/3/38/phk77njzeone93jesnt0m4e8s7srx4p.png","/map-media/d1e15f63c65facc25fe8.png":"https://patchwiki.biligame.com/images/nrc/8/8a/joqqyr7wse7f7df9ifa47fcg9gtrwad.png","/map-media/0ac004879390157d1999.png":"https://patchwiki.biligame.com/images/nrc/f/fe/6bo7h81x4vf0wmsig5e6uqgubck69xm.png","/map-media/91835a3920050e33acba.png":"https://patchwiki.biligame.com/images/nrc/d/d8/5ru6jmdisoz8ljlhacffojhr4d6c94r.png","/map-media/8c7da7da39554fc53de6.png":"https://patchwiki.biligame.com/images/nrc/8/88/2axrsiesl8f8mkb6gme8arqz8i1r866.png","/map-media/8da1364e679f542785de.png":"https://patchwiki.biligame.com/images/nrc/2/28/48dx2nnwdqf6j9m5h2akv16xvwmcjt1.png","/map-media/df0bf981c5721f0bad7d.png":"https://patchwiki.biligame.com/images/nrc/6/6a/ncszmif3o166f629az0emu7vwczekr4.png","/map-media/e63b4fd81457a6d14c89.png":"https://patchwiki.biligame.com/images/nrc/5/59/9rfo7bg8jd66nij6oxho3pau4sbgn2q.png","/map-media/c4f76c3f9cd552edc78e.png":"https://patchwiki.biligame.com/images/nrc/b/bb/rhjmagankc181hrk113mp970084d6s0.png","/map-media/d0bddfc4c8bf615973c4.png":"https://patchwiki.biligame.com/images/nrc/5/53/6wzk1t15xjw71e56u4pfloyep0rnke5.png","/map-media/ce92877207f5d1dc3c44.png":"https://patchwiki.biligame.com/images/nrc/d/df/i5fctcx8q7djcznzcvkqwpy359m14f3.png","/map-media/01e984c4d007535044ef.png":"https://patchwiki.biligame.com/images/nrc/a/a9/swacbze1z9q7f4tpinhkmf5d7hea0nb.png","/map-media/5eb1f0fcbedeb677db82.png":"https://patchwiki.biligame.com/images/nrc/5/5b/k8st7p3zwmrg0hrbmmflf7ntdj176l8.png","/map-media/d5aa7052a5ce317e7c04.png":"https://patchwiki.biligame.com/images/nrc/a/a8/g06n8m8i2a55wy6te5877ygvt7a313f.png","/map-media/ccb502d195d7bd5a381f.png":"https://patchwiki.biligame.com/images/nrc/4/47/fzveb9sgrngbw88p0566dl0zyta99yq.png","/map-media/953f8a8535d3d5079803.png":"https://patchwiki.biligame.com/images/nrc/d/d1/72l10xfvcoz19d61gwtjkjvb2m19rfd.png","/map-media/a2cb6853e24614d3cd12.png":"https://patchwiki.biligame.com/images/nrc/a/a4/b5n6tvz5803r028zbwyiy7yibmsvhlz.png","/map-media/149e18cab6d2bbb1e61c.png":"https://patchwiki.biligame.com/images/nrc/f/f5/be6nws7fmo45e2u6fa8hwoat0jyiu8r.png","/map-media/5f58a9baa538889fa267.png":"https://patchwiki.biligame.com/images/nrc/9/91/7hllrv0jeltn2kputctwtu9j3arl4sl.png","/map-media/812f5cdb63abc92394d9.png":"https://patchwiki.biligame.com/images/nrc/d/d3/3daefwspfdmnhnohh9qj43fkx8yst64.png","/map-media/6eb64d3f498de6131787.png":"https://patchwiki.biligame.com/images/nrc/1/13/dd59yas5aaoj0p3z3j7xlflboh2dr9z.png","/map-media/3a5964fd38c7c8225d62.png":"https://patchwiki.biligame.com/images/nrc/2/25/rlcnkzalv0chnhpxv7eitcnd35v2smc.png","/map-media/3a5a0107ca4d610296b7.png":"https://patchwiki.biligame.com/images/nrc/a/ad/finafcj5n606yit4f65enkh0c656oys.png","/map-media/296cd6542c8a1942de93.png":"https://patchwiki.biligame.com/images/nrc/0/01/ayekxyjcdp5c8itqqxvz0nfn5o4z8qg.png","/map-media/237c4746c87d685d29c7.png":"https://patchwiki.biligame.com/images/nrc/e/ed/34d16b9hfunhq74k0xd0y5hvf9sbjo5.png","/map-media/160e9c95b66e0c506deb.png":"https://patchwiki.biligame.com/images/nrc/e/e6/b28t9d088fwuix9mdibvec4vr94bfrf.png","/map-media/0635e2305caa1a02d145.png":"https://patchwiki.biligame.com/images/nrc/e/e1/f44cylmtx41t28r0h88677tcz5qhys0.png","/map-media/9914d2a11565492b28d0.png":"https://patchwiki.biligame.com/images/nrc/b/b8/0sz69bwupyh7gr4pwuefey4cbeqzjnr.png","/map-media/b83e4439ad043a536c76.png":"https://patchwiki.biligame.com/images/nrc/5/52/kyl3i5tnu405a00yfe93kj2cy4wgort.png","/map-media/74cd70be6ab41ef8ab08.png":"https://patchwiki.biligame.com/images/nrc/2/20/j3cfsgkv8f27mmx24157o5qlyxlzkn2.png","/map-media/649aca73dd72401edc67.png":"https://patchwiki.biligame.com/images/nrc/b/b2/hmzt04rjfpxisl0b16e80ko7g4rrdr7.png","/map-media/337311c8811a8c11dc97.png":"https://patchwiki.biligame.com/images/nrc/b/be/d79ektrydo3ck04ko5ulqj7mqqs8j6r.png","/map-media/9343ffd181d7dd17aa01.png":"https://patchwiki.biligame.com/images/nrc/6/61/n87oqfzdczfui6wcfua9vddw6we9ur0.png","/map-media/3263c3954335251d5b23.png":"https://patchwiki.biligame.com/images/nrc/2/2e/ejtx6fy13ufqzrm7sq9v6r4is8lz45l.png","/map-media/be0e043581c3fea248d8.png":"https://patchwiki.biligame.com/images/nrc/9/92/ljqxb1wnilfjxs2gm3zec4nmyzbc60c.png","/map-media/9822262423ecff9eb5e0.png":"https://patchwiki.biligame.com/images/nrc/a/a3/gwdg6fg7txyc7fnmp2aeo94krh09kov.png","/map-media/a051050cec28e966db65.png":"https://patchwiki.biligame.com/images/nrc/2/2f/c7vjzcik6g5xoif1bya1vm7bm8bpizr.png","/map-media/21e4843449ec4f382808.png":"https://patchwiki.biligame.com/images/nrc/0/05/2l0ph2jnnojv3427aqtl44rah2by9nn.png","/map-media/16ea159ed949de896a0e.png":"https://patchwiki.biligame.com/images/nrc/3/3c/bxphl203c97mxk2c2moaq2q5siwj7ew.png","/map-media/d8e37d054039eab673d5.png":"https://patchwiki.biligame.com/images/nrc/7/72/8mdikjtlgawqh5ax70bus1cvw869ejl.png","/map-media/1552a84db99daf3e6016.png":"https://patchwiki.biligame.com/images/nrc/5/54/lttjkanxog5rk0wsk33weys6zk8bfgp.png","/map-media/ff10683a35253b260302.png":"https://patchwiki.biligame.com/images/nrc/e/eb/5anbvayqd4sm101pl5vcuybpnxow4or.png","/map-media/cd7cf7c48cee51411cf6.png":"https://patchwiki.biligame.com/images/nrc/0/03/52eblhcvrjpraz3ba1d133el8utc4wc.png","/map-media/56aaa8cdecbcbedd940e.png":"https://patchwiki.biligame.com/images/nrc/4/46/011z8c2glcx36tiom3rjdxobysdqzfw.png","/map-media/e3a434ba65fa57de3276.png":"https://patchwiki.biligame.com/images/nrc/5/58/s16yqyd3d209zua4i5wq0yduf3woejb.png","/map-media/d8ab790b11404cf484b1.png":"https://patchwiki.biligame.com/images/nrc/a/ac/c24a3b5j85yuge4r7r0xb7w46n00z36.png","/map-media/18b3f924f654226ce781.png":"https://patchwiki.biligame.com/images/nrc/0/04/ff7obvfdo17miegn8i3wl8w9pdwcm2u.png","/map-media/1807db0746c78aeb3009.png":"https://patchwiki.biligame.com/images/nrc/9/92/ovputzttwy4hd52l4q2186clyhqjg6d.png","/map-media/2825d71991b1fa6953ac.png":"https://patchwiki.biligame.com/images/nrc/2/2b/k08jzv78betovt9vwr8y852kk58vaby.png","/map-media/f8bad3dea2c791551b21.png":"https://patchwiki.biligame.com/images/nrc/4/45/icynvc3urv2wfmgr5k494lmkrrfwt8z.png","/map-media/5b3a8bfd8bf9225ce627.png":"https://patchwiki.biligame.com/images/nrc/3/35/lsjq3fhxflj1rjs39b3uys8ul32uu3i.png","/map-media/f73eef20815f297ef23e.png":"https://patchwiki.biligame.com/images/nrc/6/68/obcylpl883choshxa47m96qlvzktqcx.png","/map-media/9a3c4795b7d1d518c3cf.png":"https://patchwiki.biligame.com/images/nrc/5/57/g5ze7r1ztnikclvzsx200s7ttfrlo6y.png","/map-media/a55498e120a8171e611c.png":"https://patchwiki.biligame.com/images/nrc/7/7d/8yuibxvxhevldciinrkraucxlzattsw.png","/map-media/6661d69d43e2b7e23cd5.png":"https://patchwiki.biligame.com/images/nrc/7/73/mv6oy3odf8ao7lbqtoh7uyqlgqxgcq8.png","/map-media/2ccb63bcc8fdff8ebe9f.png":"https://patchwiki.biligame.com/images/nrc/b/b9/4g1wo8ih1nwnhvb5s8z8n7knmpen7bz.png","/map-media/520796dba836e37df283.png":"https://patchwiki.biligame.com/images/nrc/8/8b/lndri9funogm7hputt66a97mdfjmxfg.png","/map-media/b7c138b15cdde370659b.png":"https://patchwiki.biligame.com/images/nrc/e/e0/chm24tj3u57jo2nmcj0w2hlnds7u99t.png","/map-media/4e3aed6b74a5b0af8cff.png":"https://patchwiki.biligame.com/images/nrc/1/1a/jpws31ild7x7x5dg6ju8phdz0vg0u77.png","/map-media/5c595123b78b5ed4babd.png":"https://patchwiki.biligame.com/images/nrc/3/3c/o9owgh4511rwksg7194d40rqabge9lu.png","/map-media/f143ba791b20367df9e0.png":"https://patchwiki.biligame.com/images/nrc/5/5d/nriruq4siq57g7teaqiow1tgsd5m90a.png","/map-media/f395a3489a857239ac24.png":"https://patchwiki.biligame.com/images/nrc/0/0f/htisa8vpcx1774e9dpx35tv9xhxclwq.png","/map-media/842669b44009f05c816a.png":"https://patchwiki.biligame.com/images/nrc/4/4d/fjynbm2de455qysr8s383zih3mue3cl.png","/map-media/7fecf5001c782ce9b691.png":"https://patchwiki.biligame.com/images/nrc/5/5c/aqpbbbtgt2ljbghpx25ax4kcmfp8a35.png","/map-media/927ba9762cdc20608c6e.png":"https://patchwiki.biligame.com/images/nrc/b/ba/r2v3x3bicq1ankzszntjgt9bbms96iq.png","/map-media/f7cd3e5f6fb023216574.png":"https://patchwiki.biligame.com/images/nrc/7/79/sfwbwqnjbbzq48yeanr6mhg8v12fw1n.png","/map-media/8801d53885b6796af7be.png":"https://patchwiki.biligame.com/images/nrc/8/81/rspsqtfxre2gxyf2at1yc72gnc9nqt7.png","/map-media/0a0ee07cef60d9cc21cb.png":"https://patchwiki.biligame.com/images/nrc/5/50/mv2f2v762ek8jir495csqgzsic26dyf.png","/map-media/17d498023e0b2209aca4.png":"https://patchwiki.biligame.com/images/nrc/8/8b/5vdag0h6x0cmquthhkhmmg0hq5x661y.png","/map-media/021e7bc048a4e27620aa.png":"https://patchwiki.biligame.com/images/nrc/a/ad/fxwmw3pxyavhnpo87m5cx487v0jnedg.png","/map-media/2850e3445dc4a5d834b3.png":"https://patchwiki.biligame.com/images/nrc/9/9a/2p2stp5hp5rxpg7urlo5rn0fzyxyor7.png","/map-media/6cb746457d55e0323292.png":"https://patchwiki.biligame.com/images/nrc/f/f7/8yn7h1d4arsntgpsg4l1brbxo1cxcz4.png","/map-media/5cbdcfc84d88a0b46999.png":"https://patchwiki.biligame.com/images/nrc/6/6a/b8fgynz32vo8nal8h6ld52be0rjjhzp.png","/map-media/75244b71903e0215f261.png":"https://patchwiki.biligame.com/images/nrc/8/84/12okuw68kd09b9qkdfepodktgordbnw.png","/map-media/8ff107018152b54ae00b.png":"https://patchwiki.biligame.com/images/nrc/0/05/fll2cr8nrnq9e11dzvqxi28pphbdigc.png","/map-media/14e8d07fe1853c087de3.png":"https://patchwiki.biligame.com/images/nrc/2/2f/5rqqxxkh5vxa738b0e46n8fh1g0y2pt.png","/map-media/e705b8a93efc2c9441b0.png":"https://patchwiki.biligame.com/images/nrc/7/72/ahnozk7q7n6kzbjgk7iy5umab6lsu0i.png","/map-media/e5444759af36a7a25426.png":"https://patchwiki.biligame.com/images/nrc/e/e1/q0emc0k279avop2sijwug3r8tdiiuio.png","/map-media/96e09e0ea689a60d0d55.png":"https://patchwiki.biligame.com/images/nrc/3/34/3dmol88p5oei7y23nt8tgijt51gfnzo.png","/map-media/a71016b54153a7a82f3b.png":"https://patchwiki.biligame.com/images/nrc/8/8e/nth2p6aif3699r2vfxbrlpndlza6d08.png","/map-media/7dd983b3d27ed2177c08.png":"https://patchwiki.biligame.com/images/nrc/4/44/dr7wa2gzvlo5oo83bo88gatrcc8k9ny.png","/map-media/0fef7ff80877679d2235.png":"https://patchwiki.biligame.com/images/nrc/5/54/hupx4wz1hj65ojt85jysbvtndjedy2z.png","/map-media/eedf53a1a31fb58dc2a0.png":"https://patchwiki.biligame.com/images/nrc/7/79/hlmx60sv9132gy6tggaost7mpo7mh43.png","/map-media/6d6bfcc31c264df7bf07.png":"https://patchwiki.biligame.com/images/nrc/e/e7/sx57g5i8qf73ibwhuoz579qb7s42jvw.png","/map-media/f84fd7c5364e310e6723.png":"https://patchwiki.biligame.com/images/nrc/2/27/4hv1l3wmmq5lqxkly52cqn3y1y4veyj.png","/map-media/19f222fe83f0930e8842.png":"https://patchwiki.biligame.com/images/nrc/d/db/10kej0tpoq3438ic7zobhte2er7f0zl.png","/map-media/c6c6f0a480328259c94f.png":"https://patchwiki.biligame.com/images/nrc/b/b6/7dhehjc3j4eq8ub5r9o35338i62um8t.png","/map-media/7d4f93b6b6b2384653ba.png":"https://patchwiki.biligame.com/images/nrc/e/e8/rdoq4hgj9lo6qc52m87xyw9wfnzkrq6.png","/map-media/f242f40ea2b64d252d53.png":"https://patchwiki.biligame.com/images/nrc/b/b0/tdn2j7jsltj8bol05ye96n7vmt0vh9m.png","/map-media/623dd3780468ff6393fe.png":"https://patchwiki.biligame.com/images/nrc/4/4f/5cl7o02pyzfy4hg659ud1a44l5f3e30.png","/map-media/0279f354a7ce174fa479.png":"https://patchwiki.biligame.com/images/nrc/4/4b/50sucmlh16xqk20jiy2ty5fsgy7bpec.png","/map-media/9fb614de1c891e24ed96.png":"https://patchwiki.biligame.com/images/nrc/3/3f/40yq299u801njpz0lxwwlwyxysqtq9s.png","/map-media/594f03febe6c6aa2283e.png":"https://patchwiki.biligame.com/images/nrc/6/6d/8pbuayxvrju0jii4ehnwly0bfccn6ak.png","/map-media/1e7de976e991f5b41159.png":"https://patchwiki.biligame.com/images/nrc/9/95/ssjsfne23sd9i02bsk9ptae6d5nyynq.png","/map-media/4da83e525846725205ea.png":"https://patchwiki.biligame.com/images/nrc/c/c4/k8q6sw1tum9gq9k9fif3a5zjc51iv8y.png","/map-media/ca4a6449653407577571.png":"https://patchwiki.biligame.com/images/nrc/7/75/tji6zi1foade1t5m9ggidu3g1i4mr36.png","/map-media/f167f141428bf13a13fd.png":"https://patchwiki.biligame.com/images/nrc/b/b2/3nw9i6x74zjfxghj1a5uqjz0y9utt93.png","/map-media/0b4d3919ae71796a0c4f.png":"https://patchwiki.biligame.com/images/nrc/9/94/sfsf76olpkltsc3eo2wj5trjzjcrg97.png","/map-media/3e02917505ea06e51104.png":"https://patchwiki.biligame.com/images/nrc/1/1d/4ygilps7iegacxnn1lt7bmanm820jky.png","/map-media/141db7a4dd9879629604.png":"https://patchwiki.biligame.com/images/nrc/7/7f/egf4bbzcyu2o7yfcbi333kbwlb0riva.png","/map-media/6b3dc81ebbb918e9d28c.png":"https://patchwiki.biligame.com/images/nrc/4/4e/gzm876191bfrpysnkipl2tfjy807imb.png","/map-media/a76bc508e27ba9a6d0a4.png":"https://patchwiki.biligame.com/images/nrc/a/a9/rhvcvt6qb4rxer8hy6awzj2ldow1et7.png","/map-media/94a13a61e2869b3471b7.png":"https://patchwiki.biligame.com/images/nrc/a/a5/0xf1qzzcrgenvyhgk371yaznsw9x1i2.png","/map-media/0277c87607ad34a9bf38.png":"https://patchwiki.biligame.com/images/nrc/5/5b/akckb8ttw9ezwje026o34kpf239mcnj.png","/map-media/2f2767b16bed02e308ff.png":"https://patchwiki.biligame.com/images/nrc/0/0a/hyybqv50aqt4sq94g190hnxgoiry9ry.png","/map-media/2ea2295ec303ab7ff4d6.png":"https://patchwiki.biligame.com/images/nrc/6/6c/ng7eb5rxd2lexvmb89bx3v2t04zmvcf.png","/map-media/4bd61ad0a4c77ddeb274.png":"https://patchwiki.biligame.com/images/nrc/f/f3/34bfi6g14ppwrzaw97bq3zt31b8zgyn.png","/map-media/2abc3a4b5844320ba1d3.png":"https://patchwiki.biligame.com/images/nrc/9/9d/s7ecjsjy4j0vx24rbmmbzhavydpe0rh.png","/map-media/fd739d250bfdbb723d63.png":"https://patchwiki.biligame.com/images/nrc/7/75/h04bziw2m2wr8rxioi2qgf51a0i0rod.png","/map-media/98839f2e3fc997fee78c.png":"https://patchwiki.biligame.com/images/nrc/6/69/8qre1hvf2mb31t1f00dkdik252j5zpj.png","/map-media/10f2370ec515d3c4e2af.png":"https://patchwiki.biligame.com/images/nrc/2/2e/rb1qrf61l8tew0nb1l4ndsijgh9pap0.png","/map-media/d9dc0cd5674acd60a0b4.png":"https://patchwiki.biligame.com/images/nrc/8/83/ik41bjt4iw38f6yqhaqh65spzli8e6e.png","/map-media/7035f5ac4ebd3c17d64a.png":"https://patchwiki.biligame.com/images/nrc/b/b5/agaq8t5npb23swfmxmrtnsm9qsdgxsf.png","/map-media/9eb81ca62b631a1a1d60.png":"https://patchwiki.biligame.com/images/nrc/2/2a/lnhq5olbxlbsb572rjnc1yoobr8ilui.png","/map-media/010486991ff5756aa88a.png":"https://patchwiki.biligame.com/images/nrc/a/aa/ez09yfxhn84sur5hiyz49wfwpfj95i7.png","/map-media/bd97b5292d0a102475c3.png":"https://patchwiki.biligame.com/images/nrc/4/43/c4evpjyko159goaxvwg4ujjwvfas98n.png","/map-media/7466992dc0d5f6b30afd.png":"https://patchwiki.biligame.com/images/nrc/3/3f/a40ba4nclg7bd3yw0wgezovrw1s07pk.png","/map-media/6694702a464eef31bf3d.png":"https://patchwiki.biligame.com/images/nrc/7/72/ht2mc1nd0hqz15a5cgxlrdb7ecter7o.png","/map-media/40d4a5a136cd54eecfee.png":"https://patchwiki.biligame.com/images/nrc/0/0c/j1uiv4mx5on3isd6dhirm7d0ch5yjtv.png","/map-media/4b28618fdbff884350f5.png":"https://patchwiki.biligame.com/images/nrc/5/5d/csefluilpa6t3enme918j1lqk0px37f.png","/map-media/071b274ae7dfdbd5e565.png":"https://patchwiki.biligame.com/images/nrc/8/8d/7319tqt954zh394f5pff5lr7r9of9la.png","/map-media/e67e12433239d5dff96b.png":"https://patchwiki.biligame.com/images/nrc/3/35/8kerb4kjp8c86grnqx68gfyhpd0jms1.png","/map-media/06792f6ba8b5d952493a.png":"https://patchwiki.biligame.com/images/nrc/2/2c/rfysjh7spocrq58wriomz5dw0asz99s.png","/map-media/e1bbfd0335855490c6a7.png":"https://patchwiki.biligame.com/images/nrc/1/15/lb4oelkrnuyicoguj00aqp88k13t8ab.png","/map-media/6c5ac1b99236f9aa60ac.png":"https://patchwiki.biligame.com/images/nrc/1/1f/ircacej1gup6wb0nl7ju3kb6yefxyz4.png","/map-media/ad1cf566e585a00b704f.png":"https://patchwiki.biligame.com/images/nrc/f/f1/5xvqzbact73xmqv7a21q6akybsrkyor.png","/map-media/762e05aa17e97d72f28d.png":"https://patchwiki.biligame.com/images/nrc/8/86/85wndfl9202vofpdppyovh53pzxx334.png","/map-media/93dc07d417395bbbafcb.png":"https://patchwiki.biligame.com/images/nrc/b/b8/j6d6wf5ll2r5z80cye6x0natgjtf65b.png","/map-media/5caf8d8932ac0c01eb4c.png":"https://patchwiki.biligame.com/images/nrc/9/9b/tmr4qs5o5s1wip4tvn3cqch1j2o1d3w.png","/map-media/f9bfb84f3b2b8cb6a94d.png":"https://patchwiki.biligame.com/images/nrc/a/a7/osdskcuuwgfd1v858gz7y6avgrmp8bp.png","/map-media/c93e1c05b0f9a2329c5b.png":"https://patchwiki.biligame.com/images/nrc/3/3c/owm6g4v9gjsyee8pycx8u5w7nclc2qk.png","/map-media/78213553c3a60b04d1a8.png":"https://patchwiki.biligame.com/images/nrc/2/21/kav9zvx3bb2qsnx4fglho2kt4c8xkos.png","/map-media/d34ff766fb3e94d894f3.png":"https://patchwiki.biligame.com/images/nrc/b/b0/1f49q87hz1kc85gfe10g7amxnagmxls.png","/map-media/9476ecd5aec4e8adbc46.png":"https://patchwiki.biligame.com/images/nrc/e/ee/gat0olnazqon27vd9rv173iva96wwuk.png","/map-media/4ed8e066b41007639286.png":"https://patchwiki.biligame.com/images/nrc/5/54/ifindo1barxowexgsubvwpy7k6c5cs8.png","/map-media/f5d4d350cac35e607dbb.png":"https://patchwiki.biligame.com/images/nrc/c/ce/q64yoegendk1yc2eytp44bsqw13e183.png","/map-media/5b4cfd19b8149a555bc2.png":"https://patchwiki.biligame.com/images/nrc/d/d6/dio477w354cxth5vr9cxfn0p55wjrul.png","/map-media/15b6bb210331d7e38162.png":"https://patchwiki.biligame.com/images/nrc/1/1e/57e1x908ncs3no1ese5swrazooev6of.png","/map-media/a27ff17a90fd7ce9d470.png":"https://patchwiki.biligame.com/images/nrc/0/00/86jgpwbq8fs1ftyou8tb37nipe717kf.png","/map-media/18485d4bdb56efc1af86.png":"https://patchwiki.biligame.com/images/nrc/f/f6/h63fafpnfwvdxiojzo7mn8fk3fh7d20.png","/map-media/d24ab777658951a221e8.png":"https://patchwiki.biligame.com/images/nrc/5/5c/hp8pvaap7h2owyfmt8uofojbvi61ae5.png","/map-media/7797cb3496a9f7c4ff2a.png":"https://patchwiki.biligame.com/images/nrc/f/f6/ktrv7vdcxmkk26qswxiu2nq85ib7pgy.png","/map-media/501ef7a834ee7a43a0eb.png":"https://patchwiki.biligame.com/images/nrc/6/63/tsdom6bflyvypzodxxslvg2p7k7mrbp.png","/map-media/3aebd39d38fae6475fcd.png":"https://patchwiki.biligame.com/images/nrc/9/9b/dml249is465wbp2q01mo0822gv2ea1x.png","/map-media/cfb793f55e4a2555af88.png":"https://patchwiki.biligame.com/images/nrc/d/d1/kgiouhm3ncu7lnf2at848jqui0p4o0g.png","/map-media/ebfbf1012ac8de51d176.png":"https://patchwiki.biligame.com/images/nrc/1/16/fcfzkf2xqgoaty23tr8jwpalc0h7bi6.png","/map-media/6ebe409d3282bc617825.png":"https://patchwiki.biligame.com/images/nrc/3/3f/e5r19t5risvt8h5dlwvyih9j1t5ocqg.png","/map-media/ffa48ea9052eadbfaa0f.png":"https://patchwiki.biligame.com/images/nrc/6/6a/ittl5m6d0yzsskwitetzwufkjwm863n.png","/map-media/923b31e3babab0a14676.png":"https://patchwiki.biligame.com/images/nrc/7/75/lb7letze9svpfkk55jl5l34mfds67tb.png","/map-media/7fb685cfb264d5240422.png":"https://patchwiki.biligame.com/images/nrc/8/82/bvc002cwd3crxmjfy1hfq10r3273cvs.png","/map-media/bfc3f3a1609cd60b460c.png":"https://patchwiki.biligame.com/images/nrc/2/25/2jfggjdfivtyod8rfxpkogiaetkz4r5.png","/map-media/31afbe38ab12bcc91262.png":"https://patchwiki.biligame.com/images/nrc/2/25/2jfggjdfivtyod8rfxpkogiaetkz4r5.png","/map-media/1e96bc0556b11333561d.png":"https://patchwiki.biligame.com/images/nrc/9/91/769ergvra3p90c188fgoflnpnrjarwq.png","/map-media/c068d5f04845e8fa7ef9.png":"https://patchwiki.biligame.com/images/nrc/7/7b/2k1o6wym79a3lwn4v44jav23ncxlee2.png","/map-media/c8b79e991eadc732ca6d.png":"https://patchwiki.biligame.com/images/nrc/7/7b/2k1o6wym79a3lwn4v44jav23ncxlee2.png","/map-media/5a848c04f44c5405ef11.png":"https://patchwiki.biligame.com/images/nrc/5/58/8ti57a28e9w23vs9yhbnioclce84ppw.png","/map-media/57b19536c9d2a7ab6a1d.png":"https://patchwiki.biligame.com/images/nrc/5/58/8ti57a28e9w23vs9yhbnioclce84ppw.png","/map-media/e200954efbb49084b434.png":"https://patchwiki.biligame.com/images/nrc/0/07/frvhqm1bt2flhaaeajale1oqkqskvz6.png","/map-media/8d4a3d0d1d778048c7ed.png":"https://patchwiki.biligame.com/images/nrc/0/07/frvhqm1bt2flhaaeajale1oqkqskvz6.png","/map-media/c359b0e38c11a7e3cfa2.png":"https://patchwiki.biligame.com/images/nrc/6/6c/mysk9kxesj0qwehit4fcnsvx5knvjd5.png","/map-media/93057c949984c3c24a58.png":"https://patchwiki.biligame.com/images/nrc/6/6c/mysk9kxesj0qwehit4fcnsvx5knvjd5.png","/map-media/32a6d2134f156cf11cff.png":"https://patchwiki.biligame.com/images/nrc/7/74/laljl4vdlz36oy4saa58dcv8d0jnx1j.png","/map-media/dcefdea43ade56867aeb.png":"https://patchwiki.biligame.com/images/nrc/9/9c/8qf7pbrulnqd5ojhfue7iuc2kzkbdwi.png","/map-media/eb99e4e92d2bdd9a8d95.png":"https://patchwiki.biligame.com/images/nrc/9/9c/8qf7pbrulnqd5ojhfue7iuc2kzkbdwi.png","/map-media/a4c5c79cc545844efdf7.png":"https://patchwiki.biligame.com/images/nrc/a/a7/jkn29d2r91l2avc2gthjmgbs91diy3m.png","/map-media/cb5a0e3a24e6e22042c5.png":"https://patchwiki.biligame.com/images/nrc/a/a7/jkn29d2r91l2avc2gthjmgbs91diy3m.png","/map-media/a8629340415aed182e31.png":"https://patchwiki.biligame.com/images/nrc/0/01/aaclrcw3zndle1jbtgojg7sylvmz4ne.png","/map-media/7aeb0aa7ba342ca48532.png":"https://patchwiki.biligame.com/images/nrc/1/19/ibbkwhm0teg778zil7ump7u8q7sxibl.png","/map-media/70bade096968caa3c323.png":"https://patchwiki.biligame.com/images/nrc/9/91/769ergvra3p90c188fgoflnpnrjarwq.png","/map-media/7d99357fe3bfb8908d8d.png":"https://patchwiki.biligame.com/images/nrc/7/7b/oug1scq6ooahpu6lyivg8q34klivrmb.png","/map-media/c1e2ea1e4178741ade51.png":"https://patchwiki.biligame.com/images/nrc/9/91/769ergvra3p90c188fgoflnpnrjarwq.png","/map-media/98951db1882a80e9e751.png":"https://patchwiki.biligame.com/images/nrc/6/61/gc2bhubukb9ldukraaa3hl6y4dyivfo.png","/map-media/090a59180a780f709787.png":"https://patchwiki.biligame.com/images/nrc/0/0b/6ut8kbx6z3zmsxhzdx9778oe8cj00ow.png","/map-media/a9db337b12e79a58afe3.png":"https://patchwiki.biligame.com/images/nrc/0/0b/6ut8kbx6z3zmsxhzdx9778oe8cj00ow.png","/map-media/50bba532e4ed142d92ac.png":"https://patchwiki.biligame.com/images/nrc/d/d8/hpsmu68wf76j2ao3fy66almyzievuxo.png","/map-media/f45868d00fbd8a6bbfe4.png":"https://patchwiki.biligame.com/images/nrc/d/d8/hpsmu68wf76j2ao3fy66almyzievuxo.png","/map-media/c71a4dacb583333615fe.png":"https://patchwiki.biligame.com/images/nrc/2/23/tt98d3qc7s3k3vjcquild3grag5hkjs.png","/map-media/6f492e9f67afd0616b8d.png":"https://patchwiki.biligame.com/images/nrc/2/23/tt98d3qc7s3k3vjcquild3grag5hkjs.png","/map-media/034b6d8b0242ac390699.png":"https://patchwiki.biligame.com/images/nrc/0/05/s97t55w7kz36hdjtwzc4xf36wp7l7sc.png","/map-media/8bc75727b612de4e9bc8.png":"https://patchwiki.biligame.com/images/nrc/0/05/s97t55w7kz36hdjtwzc4xf36wp7l7sc.png","/map-media/28437983ff85ed4c516e.png":"https://patchwiki.biligame.com/images/nrc/d/d8/9h2u70m7c31g33ruc8jfoicd01rg4t1.png","/map-media/44c7325aa8cedb40bcff.png":"https://patchwiki.biligame.com/images/nrc/f/f7/ks3wrxyqp96i39kt1mov31y5hh41giz.png","/map-media/05ecfc0fadcf1aa47613.png":"https://patchwiki.biligame.com/images/nrc/5/57/admqnpa4o02tfratkq22fpe95m6cnwm.png","/map-media/69fd142a724a65399685.png":"https://patchwiki.biligame.com/images/nrc/c/cb/nvk6tzkd6mhatt9wz6qr32kny1xljbf.png","/map-media/3b9dd1d4bcf536034a01.png":"https://patchwiki.biligame.com/images/nrc/b/b0/kitg9ky40l0iv3h8nvhd1vmx0px7y5a.png","/map-media/9c8c7182e6d2eb56190c.png":"https://patchwiki.biligame.com/images/nrc/5/57/admqnpa4o02tfratkq22fpe95m6cnwm.png","/map-media/7179f59d84bfdf44edd9.png":"https://patchwiki.biligame.com/images/nrc/c/cb/nvk6tzkd6mhatt9wz6qr32kny1xljbf.png","/map-media/15dd4cce8e8aee67eb46.png":"https://patchwiki.biligame.com/images/nrc/b/b0/kitg9ky40l0iv3h8nvhd1vmx0px7y5a.png","/map-media/95ee463a7b0ebda81ec8.png":"https://patchwiki.biligame.com/images/nrc/a/a8/c0kn4kofar89c2txqnllzn14k3otipi.png","/map-media/ae89346946e55b523318.png":"https://patchwiki.biligame.com/images/nrc/4/4c/6o1b06xvd3yn8ma4fmx1zqcoxplfzpn.png","/map-media/0d7eee947e6565ceaf5e.png":"https://patchwiki.biligame.com/images/nrc/8/87/tlm57r61ab5pfhqdfeikcugmqvlv27d.png","/map-media/7d37ed5a6f86e9bbfdb3.png":"https://patchwiki.biligame.com/images/nrc/5/5e/38subaazriwzj5tq5rd7reuz93dh8j7.png","/map-media/1b25e2490fc05f6e7028.png":"https://patchwiki.biligame.com/images/nrc/2/28/e6neb5ojnd0s22uthusmh81cqg7mzn4.png","/map-media/9d5ee20025a160ecd5a4.png":"https://patchwiki.biligame.com/images/nrc/8/8b/ha1fl2oef7io4ox6m9jufws7sjlzvl8.png","/map-media/b7c491142b43b4f9dbd3.png":"https://patchwiki.biligame.com/images/nrc/8/8b/ha1fl2oef7io4ox6m9jufws7sjlzvl8.png","/map-media/57b68324d9d17c43fe54.png":"https://patchwiki.biligame.com/images/nrc/8/8b/ha1fl2oef7io4ox6m9jufws7sjlzvl8.png","/map-media/d2c447b8369511d3ab82.png":"https://patchwiki.biligame.com/images/nrc/8/8b/ha1fl2oef7io4ox6m9jufws7sjlzvl8.png","/map-media/d8492ec5a320ec1ba96b.png":"https://patchwiki.biligame.com/images/nrc/8/8b/ha1fl2oef7io4ox6m9jufws7sjlzvl8.png","/map-media/e72062c5846940ea0633.png":"https://patchwiki.biligame.com/images/nrc/9/98/ei1gagh4yy2m70o2zqlvlomaar1fgw9.png","/map-media/f04e2eaa508a1b491d2f.png":"https://patchwiki.biligame.com/images/nrc/8/8e/tvum1os0qat4u33tfefps5z9562f4nj.png","/map-media/c8ae3aee2ee5a0abe8a2.png":"https://patchwiki.biligame.com/images/nrc/d/d7/i99qlt0lyuumbicl9nverou0foeuye6.png","/map-media/db3053c2e5ac7672d6c4.png":"https://patchwiki.biligame.com/images/nrc/d/d2/m5r5dx8cxz8gjbntgon1elp6m1hihd9.png","/map-media/af5cfcca518376172b6d.png":"https://patchwiki.biligame.com/images/nrc/7/7e/6f3f7jse2nfe5hltfpudp34ii1h1dyx.png","/map-media/8e2a8a652ade99aa2307.png":"https://patchwiki.biligame.com/images/nrc/5/50/c1pkiyx4nzz1mznf37i83gy973j0y1v.png","/map-media/b5b4f9b5387dab046954.png":"https://patchwiki.biligame.com/images/nrc/0/02/fj2dzam7i2o5kxhzs44dm5rfbhaiwi8.png","/map-media/a78916beb1c28ac83ac0.png":"https://patchwiki.biligame.com/images/nrc/4/4c/hbw20i1aj30t3sa0wi2jgphmeow7fc1.png","/map-media/b4d3b937a71d570506dd.png":"https://patchwiki.biligame.com/images/nrc/9/9b/cog7qvk4ds7m51yx553x7jk2ootiuka.png","/map-media/8665a6ff00823aa3e9a7.png":"https://patchwiki.biligame.com/images/nrc/e/ec/0loky7l4ssbq7cb4he25uvcz3qjst7e.png","/map-media/47097c0d72a35c3abef4.png":"https://patchwiki.biligame.com/images/nrc/2/2a/pkrrkgs7oiis2ja89ng2pbzawao73zv.png","/map-media/2b6d3cc26fb3d1ce9d5e.png":"https://patchwiki.biligame.com/images/nrc/e/e6/q7wqia0u1023gwp6ufutvrbpw19evge.png","/map-media/fc77d32a0978307fab31.png":"https://patchwiki.biligame.com/images/nrc/6/61/90e9di0m4kqqnjqn2krl7qvz2hzzft0.png","/map-media/4604d6f1ec92c0c1478c.png":"https://patchwiki.biligame.com/images/nrc/3/3c/fr45y6l6t1fsv6nrqvhif576i7wnx7w.png","/map-media/c6cae1d76f8977c7c473.png":"https://patchwiki.biligame.com/images/nrc/2/27/piwl39vyml3dowbbrk2hf2d9ny8cdds.png","/map-media/0c9972dfe67c46e01ae1.png":"https://patchwiki.biligame.com/images/nrc/b/b4/3crc0q0hin7q15ssmgkx4iv4tz0kuue.png","/map-media/21fb7c2bbbeb2e674b0f.png":"https://patchwiki.biligame.com/images/nrc/7/72/2rorp8t2xfj9uplv25aibv6tbeu9gec.png","/map-media/1ac56cbc6fbcc9d1aa45.png":"https://patchwiki.biligame.com/images/nrc/4/49/p7d22bnlrbaajyo9263qr7pa2pxk9zx.png","/map-media/c4039857e9b740b2baab.png":"https://patchwiki.biligame.com/images/nrc/2/24/nq2eu6q8evkc7kqgm3zkav0061jq8r2.png","/map-media/bde5571ef7e85d57d38d.png":"https://patchwiki.biligame.com/images/nrc/2/2e/lo9otfrc7ay5948yjmap8w3c5pxzg4l.png","/map-media/53bff7928df019b055b8.png":"https://patchwiki.biligame.com/images/nrc/e/e6/han4e2wg2e45ehzvv2z1tfqaig7chbv.png","/map-media/aefea63074b2dd495911.png":"https://patchwiki.biligame.com/images/nrc/0/0c/kk3bx9898si06riluv0h12sflnvmt2i.png","/map-media/030add33304d184cd84b.png":"https://patchwiki.biligame.com/images/nrc/6/64/r5c5jyy3kinoxkxhrpt706rj2rb5qrs.png","/map-media/31646beadeb3fc9f2d8c.png":"https://patchwiki.biligame.com/images/nrc/d/d8/pu3oy9bon4xhsvrab2uyij1gdhgj7or.png","/map-media/7d6b95830cb5cdaea38f.png":"https://patchwiki.biligame.com/images/nrc/2/2a/ktch5kgnf4r08l5vusseyj1kol6lziy.png","/map-media/2efd07837ffa9b11e337.png":"https://patchwiki.biligame.com/images/nrc/0/04/6749r51fs7e6grfh4dyhmmvs8v5chad.png","/map-media/550a279d7d535550d59f.png":"https://patchwiki.biligame.com/images/nrc/4/47/ozkcwpuyxg943jkhb6deifs5fchxl0q.png","/map-media/61efb0eecabc5ad3274c.png":"https://patchwiki.biligame.com/images/nrc/f/f2/0h9fofxzl1hl8qheh0wmqvkvj2h8dyg.png","/map-media/391c86edfd5932656257.png":"https://patchwiki.biligame.com/images/nrc/e/ed/nfqpxco38ovxkq54dh87g1510ic4ctk.png","/map-media/f02cd85c7c5d51e4db1a.png":"https://patchwiki.biligame.com/images/nrc/f/fa/btyc9xizhnciauh6vfeew9kmmg5xozs.png","/map-media/60b39833f31cd45e1217.png":"https://patchwiki.biligame.com/images/nrc/5/55/qq6rhl7q4q10uu2tvbya089qckyj5lx.png","/map-media/b9fbfa4a5efa4cc3a4d3.png":"https://patchwiki.biligame.com/images/nrc/3/3e/3zc3twz71md42pzadl17zzwddbiktbz.png","/map-media/8095b3380fb3f3d1fd51.png":"https://patchwiki.biligame.com/images/nrc/9/9e/3i5863rg5jhzf1iz1h6fzio5but80j7.png","/map-media/f0870e681bf95eb4309a.png":"https://patchwiki.biligame.com/images/nrc/6/64/e5qoqmz8vcnd6fldn6lf57g7kl6uu42.png","/map-media/3322c119e4f1e5dbcc04.png":"https://patchwiki.biligame.com/images/nrc/7/74/ic47ovj6qopkd3lwawotiey389xuxf0.png","/map-media/140320eb0ce722cb5d78.png":"https://patchwiki.biligame.com/images/nrc/a/ad/n24ea49q5vwox5conf50rww7j62jom2.png","/map-media/6b8d8d78ff9020795a38.png":"https://patchwiki.biligame.com/images/nrc/a/a3/btpf7z9ycijem49usqkhfpdomucvh8z.png","/map-media/8b3056c465012f75b4f6.png":"https://patchwiki.biligame.com/images/nrc/5/5c/1682adpqnlyai0ogn2bvgkz0lqkvgin.png","/map-media/1cfc7bb11259ca75d7af.png":"https://patchwiki.biligame.com/images/nrc/0/0b/12v7slsqlxtd6io2akdwq6vs9isfgoe.png","/map-media/9a43e4796c43ee61cb2a.png":"https://patchwiki.biligame.com/images/nrc/f/f8/eeegde95tcj3t9ay5jxdveuqxdwks7l.png","/map-media/3f83507bff3a2c7a24ab.png":"https://patchwiki.biligame.com/images/nrc/a/a7/otk73l8zypjegm32v6mc5zd13nxipc5.png","/map-media/0a2915dc7da7cd727a3c.png":"https://patchwiki.biligame.com/images/nrc/9/9d/l8oqb9k71nzfpvin0u85rgo361m2ul7.png","/map-media/e8cbe5b7ebd39a76c514.png":"https://patchwiki.biligame.com/images/nrc/0/0f/2edbjibyued8wypul9lzg2rdra6sne7.png","/map-media/69087b2c25f54b48fd1a.png":"https://patchwiki.biligame.com/images/nrc/6/6a/gxdqb12him7zd0q8j77gbik1lvgjxxq.png","/map-media/4f367c1d0c0667a1dee3.png":"https://patchwiki.biligame.com/images/nrc/4/4b/39e1bidlo3k80p3vcy1puhv6qcbeyq7.png","/map-media/9f0a30d1ede0af705222.png":"https://patchwiki.biligame.com/images/nrc/e/e8/dxw0jong1vyoj6ef27o0o7f1t4nenii.png","/map-media/e06e7a017fac0747e94a.png":"https://patchwiki.biligame.com/images/nrc/c/cc/p4o5y62go82lq3ezt2c5xi4rbwqi67z.png","/map-media/f46f88b3ec85825ea814.png":"https://patchwiki.biligame.com/images/nrc/d/d3/5401fsnaatqy0g16iztpgjfprhsk2t0.png","/map-media/accca00d5e9d101b1b4b.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/c667feb59fa80821f1b3.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/6c500e8e3a0bb82104e1.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/402648cacd938f14721f.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/77a5d7ea224a44190cb4.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/f07a12106b95af256e5b.png":"https://patchwiki.biligame.com/images/nrc/c/c6/ryb84zntzparzbjgx6f8wwvh1x9549n.png","/map-media/ca684e3012dd6b5baed5.png":"https://patchwiki.biligame.com/images/nrc/f/fa/1yxogv7g6yfsg8z5vblgfyo6avs0ft4.png","/map-media/439ddcb730c992ee47cc.png":"https://patchwiki.biligame.com/images/nrc/6/6a/91w0rnwt1nog92mrfcul8stdh0azhzb.png","/map-media/705faa1eb8bbf7b7ee58.png":"https://patchwiki.biligame.com/images/nrc/4/43/plzjvukhyxl4o05ibtrfyh8viks4o3t.png","/map-media/2d453e8e90b2405f7d23.png":"https://patchwiki.biligame.com/images/nrc/b/bf/fxkq1mg3dex8n9ofnbm5sbireony9pr.png","/map-media/e74d184c6fccbbd720ad.png":"https://patchwiki.biligame.com/images/nrc/8/85/lcuxjujwaffje5ssrc3xe8458s63fp9.png","/map-media/912e622ff4e53447b850.png":"https://patchwiki.biligame.com/images/nrc/f/fa/hvfk0yhur8zbre1hz7z6p146rn1wk2p.png","/map-media/b613a861ef183f77306d.png":"https://patchwiki.biligame.com/images/nrc/2/2e/4khk1653161pny0m7daa6cqmwknogg6.png","/map-media/b644ec380f7762d1d267.png":"https://patchwiki.biligame.com/images/nrc/c/c8/9rxf7erngqxf3t8by2j7e8j3ouk95ft.png","/map-media/437adac666cd34924fff.png":"https://patchwiki.biligame.com/images/nrc/0/06/1i26o1ztiee6r7ee34bjrfpgwdka26r.png","/map-media/574c207276316b75bcd4.png":"https://patchwiki.biligame.com/images/nrc/c/c5/6p1d2v7urx12ik7872y8yf8g0t49kqp.png","/map-media/0b6575d36e2f20c2dabb.png":"https://patchwiki.biligame.com/images/nrc/6/6d/4i6vfgwyzos4xzany6k7hmvykcmzu8a.png","/map-media/52b5c6898f54d6759394.png":"https://patchwiki.biligame.com/images/nrc/c/c6/m24cm67521u4rzs51cl66uf81hlm98d.png","/map-media/6cb38bc81fbc7be0a7f0.png":"https://patchwiki.biligame.com/images/nrc/b/b8/skwp0olt1a3p76h5kcm7qpifu6fy6ee.png","/map-media/b2f24497e5df9f4f43a9.png":"https://patchwiki.biligame.com/images/nrc/8/88/clkzdbnpyeigb5cyldov6j3lrdfro9c.png","/map-media/2a6c75cda71ff56856d7.png":"https://patchwiki.biligame.com/images/nrc/7/74/ta009514axu0mmost8wga4yvsy2z8gz.png","/map-media/9f199ee0536a9b3c1e13.png":"https://patchwiki.biligame.com/images/nrc/a/a9/hvrx2v9syj43pir2td3jydzbu6rc66d.png","/map-media/0ca904b019dc9f7ad389.png":"https://patchwiki.biligame.com/images/nrc/3/33/7dxm1u2ti8133334fvsrnqscheu2aac.png","/map-media/b832bdcb5954ef8295a7.png":"https://patchwiki.biligame.com/images/nrc/3/3a/nibx9uhm85lnow4w3kn5n390sr9js8c.png","/map-media/56e444a3332142ae3ccf.png":"https://patchwiki.biligame.com/images/nrc/4/45/6o1c5jgiam78f613d80ar2jhv820y8j.png","/map-media/966db2606b2fb162e00e.png":"https://patchwiki.biligame.com/images/nrc/8/84/mi9rgu871dxhpfj57xq9ocm1qujrc33.png","/map-media/2ad31514e8f7878365f4.png":"https://patchwiki.biligame.com/images/nrc/1/17/rquhz2zk5xh7gwvl8mqqob8otqgy4jn.png","/map-media/b28b50e576b1d2ff0d73.png":"https://patchwiki.biligame.com/images/nrc/f/f3/du17y7jg0xcx7em7e3oyfnpg240ndn8.png","/map-media/3d152918eb8e683355fa.png":"https://patchwiki.biligame.com/images/nrc/0/04/0q5ql0k0bsfi0k2jq11ct23mlf8j426.png","/map-media/d5e192b86834c0b0e30b.png":"https://patchwiki.biligame.com/images/nrc/9/91/cxi0fvq8al4nrj2blrvt7k0fufp1afq.png","/map-media/babd2f11e0345900a761.png":"https://patchwiki.biligame.com/images/nrc/9/9e/85xzjf35xrn1evh5l0w0603im8pms3z.png","/map-media/f049fd3ccf2f2514bd40.png":"https://patchwiki.biligame.com/images/nrc/2/2b/5c3chy4q7viy6gdlwoa6j1hw7up8kpn.png","/map-media/65d7bab47f81ac630519.png":"https://patchwiki.biligame.com/images/nrc/8/87/co7y0m6tm21zuz2s50uqwljuh3j7jyg.png","/map-media/fd87867a8a0e2e7e8355.png":"https://patchwiki.biligame.com/images/nrc/3/3d/1if88t3hqwde2i44t9al5uv4jgjp7zs.png","/map-media/3cb1b4623c1c3e89407f.png":"https://patchwiki.biligame.com/images/nrc/b/ba/3oihbyyhm6p5nwknv3shyurh9bkv0s0.png","/map-media/b49f856c77d60d17db48.png":"https://patchwiki.biligame.com/images/nrc/1/11/t2vopaxrwvxbsvz6m40mzk85wpva4ca.png","/map-media/83d4acfeb0f2e0209e83.png":"https://patchwiki.biligame.com/images/nrc/9/96/9fcus3fh29ym8wll8b9sxor9vqjrqtb.png","/map-media/01afa9092e6eab7ea297.png":"https://patchwiki.biligame.com/images/nrc/8/8d/1bjnazskbingsb2ix69y80zmfxgv8s3.png","/map-media/46b4c5d18e17bb9dbd72.png":"https://patchwiki.biligame.com/images/nrc/f/f1/5mafgupbj5jgdfzbc5t1c169jqc799g.png","/map-media/5ace3b86e331d9157bab.png":"https://patchwiki.biligame.com/images/nrc/b/ba/des9o8w3z9nvnxt7038dhgj4gexlgv5.png","/map-media/9c0fc10d565f184bf685.png":"https://patchwiki.biligame.com/images/nrc/d/d6/38sa8802i0jaojddh08fizt5waf13xd.png","/map-media/bf121d119c31181e1652.png":"https://patchwiki.biligame.com/images/nrc/e/e9/f00mv302xf8kozky0h86csm7yv3umqt.png","/map-media/e05abc60a7b3535209f8.png":"https://patchwiki.biligame.com/images/nrc/5/53/mt1di8b3hthywvf809c7kdi3z2z8qwh.png","/map-media/d98994aa6a3cab2876d4.png":"https://patchwiki.biligame.com/images/nrc/b/b7/112od20cucj3uk93kwe6ewmdvm9ljpg.png","/map-media/305544dd51ae5c04d570.png":"https://patchwiki.biligame.com/images/nrc/b/bd/dy3mvf1zwf5gg8l4yud2n115u21e5xt.png","/map-media/b84374e4b7656cfdfb2f.png":"https://patchwiki.biligame.com/images/nrc/8/85/t8pzzovmprqe2dklcumxumhcim2cpz3.png","/map-media/8518659864be19fd0aff.png":"https://patchwiki.biligame.com/images/nrc/8/84/4vl0qr5y53xdhbsv51r8h2qbb3g45yd.png","/map-media/8d483054aef5e4a466c4.png":"https://patchwiki.biligame.com/images/nrc/b/b9/guda8zus94dhx7i0d2zfb2b3nyczqvz.png","/map-media/5ee5ed864cbe0fcb66b5.png":"https://patchwiki.biligame.com/images/nrc/d/dc/p1ia7t6zxk47w57xrs7hkmqmt07owzd.png","/map-media/4ec13c25f35df1886378.png":"https://patchwiki.biligame.com/images/nrc/f/f3/0hk80mvsjp1r3ugwsj031ia58620vvy.png","/map-media/54b85c844269b6654827.png":"https://patchwiki.biligame.com/images/nrc/c/cb/767dnogxbfjg4ki4gwp2h445keqch4s.png","/map-media/bbd697bb9c89bdf77d42.png":"https://patchwiki.biligame.com/images/nrc/a/af/lzmdlg8snrwaomck36s0tv4fapssfhx.png","/map-media/fc156c43f70bac04e383.png":"https://patchwiki.biligame.com/images/nrc/5/5f/5dpp4wh24xqtsngeq8kveh6f5neo2we.png","/map-media/55116c57c15466a63cbf.png":"https://patchwiki.biligame.com/images/nrc/3/32/535i7n5sxc4hmgbaghjtkzy8o2nmx8y.png","/map-media/6d6995ec807fbd9075d2.png":"https://patchwiki.biligame.com/images/nrc/4/4b/dginc8rigquuhjw3bni1n6eo9b90buv.png","/map-media/b3bac103ff69d17859e0.png":"https://patchwiki.biligame.com/images/nrc/f/f1/5g87qfg4ofxihlpol5yhbv629hh8fsm.png","/map-media/ec1eaca08c086a41a782.png":"https://patchwiki.biligame.com/images/nrc/a/a1/1tznq3p81tvynr82yvq5lc8hx11w0rz.png","/map-media/d794534a677508d08633.png":"https://patchwiki.biligame.com/images/nrc/d/dd/4huxf6wcqienzoegi9g2s168tlca9g6.png","/map-media/76b80cd4cdf5689782c3.png":"https://patchwiki.biligame.com/images/nrc/3/31/lv3lk7h1ulgnuwv8zt8hwliwvegsxaa.png","/map-media/a6d9d9688357bb0d6050.png":"https://patchwiki.biligame.com/images/nrc/e/e7/alx8euwfyzhqn15zmgffwqiupb57w5o.png","/map-media/d26f0e905728a414070d.png":"https://patchwiki.biligame.com/images/nrc/b/bd/hikuv39w2cfmurwy4q0ur7wcrdtk32q.png","/map-media/57a82017d4ea542fde8c.png":"https://patchwiki.biligame.com/images/nrc/f/fb/451y4iyzbcmm9ew3h329pvxz9154is4.png","/map-media/0016b334d4a109e811a1.png":"https://patchwiki.biligame.com/images/nrc/1/13/284hn2ciji49xcrlym6989ifu7ic5xg.png","/map-media/c62153769e3b47b31dd5.png":"https://patchwiki.biligame.com/images/nrc/7/77/qyk9okyi9obq15lw5566sz9ix7ln2jr.png","/map-media/e1e4df96ec9dbae025aa.png":"https://patchwiki.biligame.com/images/nrc/e/e7/igk9adfxx2q0bfbzre5vh06sxuv7qk5.png","/map-media/ed893b1a1bc5d65704e2.png":"https://patchwiki.biligame.com/images/nrc/d/d8/pzycqfclpxca3h7q4whraqmanlifi70.png","/map-media/efacc5b81269fdb89b3a.png":"https://patchwiki.biligame.com/images/nrc/6/6f/oumel2itbiw04gkp3h6vtl1xhuvaqj1.png","/map-media/b50d33988703f926e29e.png":"https://patchwiki.biligame.com/images/nrc/8/8f/r1o5p6l8xjbir3v1h88cf2qa03wsekk.png","/map-media/f399bf3abe1d8d24d3c6.png":"https://patchwiki.biligame.com/images/nrc/4/4c/l2xjcnfz6cdcqtb2jxm6lt1ea89akhr.png","/map-media/50079b619b0d50a1dd4a.png":"https://patchwiki.biligame.com/images/nrc/3/38/smsytwr7bonc0x3ydepp8bc61x1fyuh.png","/map-media/0774524f8810f48777f5.png":"https://patchwiki.biligame.com/images/nrc/4/4e/cafbyktlpp1yv8i8y66wskb9dle6alv.png","/map-media/5105a1b28c75eb51ad87.png":"https://patchwiki.biligame.com/images/nrc/4/4d/4c1vbalt602j6d8499txyfelk01lvkg.png","/map-media/662b17548009db856d41.png":"https://patchwiki.biligame.com/images/nrc/4/49/7yuftxask7a5a6fctwdlt76bg0m32f9.png","/map-media/a053636e27cf9785bee1.png":"https://patchwiki.biligame.com/images/nrc/8/84/tvhm1asl43mn6e2mp6t5d1r7f35pv5p.png","/map-media/8ce584b64cc8a8aa18fb.png":"https://patchwiki.biligame.com/images/nrc/e/eb/0fappzhxmlq1eqvxcj3dazeoey4q07j.png","/map-media/0e3e43c93299b345bf8f.png":"https://patchwiki.biligame.com/images/nrc/5/51/rxhzayrcygsm8gd81e37m2459tl3v3d.png","/map-media/ea0fda499461c38f3359.png":"https://patchwiki.biligame.com/images/nrc/8/82/k3gq9h3gq6ptndbrojda19fw7xc7oud.png","/map-media/4d7e0efc720a391cc531.png":"https://patchwiki.biligame.com/images/nrc/d/d5/luny442k7mbhxl1lmq0v4st0s5o5eus.png","/map-media/a40364f6b1c9bfbda9db.png":"https://patchwiki.biligame.com/images/nrc/0/0d/hkrbx0en8i1w1rszukuaenjdjdpnqa6.png","/map-media/fcdb34f508681425b38f.png":"https://patchwiki.biligame.com/images/nrc/b/bc/bohrjpkk39jfuuvxyczvgpqe98x0164.png","/map-media/17b631bec8811884d14b.png":"https://patchwiki.biligame.com/images/nrc/e/ef/2ti7ee9a4smbezvy7zk82swjtj15os8.png","/map-media/9fc26709d22458d191b0.png":"https://patchwiki.biligame.com/images/nrc/7/71/3mwud6fvfn8f31k9xw3sqy9auwg2yqf.png","/map-media/389df4b59fc169af9b14.png":"https://patchwiki.biligame.com/images/nrc/4/40/c76k0hjypxl2gkciauqhy7gymxfmchk.png","/map-media/7eb55ee6795e655744d4.png":"https://patchwiki.biligame.com/images/nrc/9/98/6xwl7os5ftdmxcyc8lt0jfsqqv0nnwt.png","/map-media/2f0dabb73c6368aa9e01.png":"https://patchwiki.biligame.com/images/nrc/b/bb/8cdmxz0pf44gb81dwqn4amd7dp8vq7r.png","/map-media/8283d99cbbeb31cf4eaa.png":"https://patchwiki.biligame.com/images/nrc/6/6a/1827jdg9md89r509edogu7t58xt6may.png","/map-media/01c14eace2851b723dfe.png":"https://patchwiki.biligame.com/images/nrc/a/ac/cwre435lh6bvdjv4p34gjn3g5enc3f1.png","/map-media/678fcf4687ea25150c3c.png":"https://patchwiki.biligame.com/images/nrc/6/6f/qwe0dmtwo497w0kf12lhyv77fi0qeg6.png","/map-media/fc913f6c018af4b49610.png":"https://patchwiki.biligame.com/images/nrc/9/9a/4mrnb7bngehvenvykq01heksch7vwjg.png","/map-media/38a6ce11fc3f131dd378.png":"https://patchwiki.biligame.com/images/nrc/7/71/5yd67vhftzo1wfnkydqu4lznpxbilz3.png","/map-media/382a76eed3272ea1a731.png":"https://patchwiki.biligame.com/images/nrc/0/0f/3bg87i5vv5c60i27xwfaroppt3nhof9.png","/map-media/3ec46c656788a5a87688.png":"https://patchwiki.biligame.com/images/nrc/c/cc/nz7yc5o95j9noq1hu1xfb60jjzqhg4j.png","/map-media/afecf3dead7d903f34a3.png":"https://patchwiki.biligame.com/images/nrc/b/b9/q9ucepregcizxz774foytyzlh416r6h.png","/map-media/612f66c862427bd7ef97.png":"https://patchwiki.biligame.com/images/nrc/1/10/eddlqpohu4xjfjoi1x9k098l0q3cpyp.png","/map-media/9192524851b13a8808ed.png":"https://patchwiki.biligame.com/images/nrc/e/e8/2humiqtqwcvliieg6iywbdieka9x63v.png","/map-media/4f419e2001dbb32645bf.png":"https://patchwiki.biligame.com/images/nrc/c/ce/1alehdc0m42g7gcvizuyzl4ypcafqky.png","/map-media/1d2b0b778ede31f0eae4.png":"https://patchwiki.biligame.com/images/nrc/4/43/044gdgt7aia63ap6a73ijz29yvwm8c8.png","/map-media/471f3874792d511e4040.png":"https://patchwiki.biligame.com/images/nrc/c/c8/5qcwb06rl9u6oovexoh9ajihcyqit9x.png","/map-media/7657fdb6211174d1dea4.png":"https://patchwiki.biligame.com/images/nrc/c/c2/pwofjf64772sh6vboxn6c9ypvctb8vh.png","/map-media/17de04874f016444da2d.png":"https://patchwiki.biligame.com/images/nrc/2/23/jn85dtg35zaemd6r0syvfldnxcjcn0n.png","/map-media/f76b10d482430cff0752.png":"https://patchwiki.biligame.com/images/nrc/b/b5/1w4aib979koratiwjopzmuckna88jqg.png","/map-media/0e447c04cce748766fc4.png":"https://patchwiki.biligame.com/images/nrc/f/f4/bynetxv08wq8b8ynncc5i9hkpih3hge.png","/map-media/10c29b0d2f2787001111.png":"https://patchwiki.biligame.com/images/nrc/8/89/onwqr9een5sn91mxptbydurursl7v2d.png","/map-media/bdca93ad0941b9c8be96.png":"https://patchwiki.biligame.com/images/nrc/6/68/3pymobnic78a0ka1y0zwzhr8bgp68hv.png","/map-media/82566c3db2d73ec204fd.png":"https://patchwiki.biligame.com/images/nrc/f/f9/imqcuucbbws2skifk874uhqy0yu3y93.png","/map-media/1ba034ffdfa48109ef8b.png":"https://patchwiki.biligame.com/images/nrc/7/79/7pqsj6dweeg9hog9mmlxcsja72uukx2.png","/map-media/62a54752b2897f78c3d5.png":"https://patchwiki.biligame.com/images/nrc/f/f3/plmvpyh9xol8xy2ko7khdx2wzru6vtt.png","/map-media/1408e423d4fad39ff444.png":"https://patchwiki.biligame.com/images/nrc/9/93/n812nvf8d60snicyyey7exm7uaanz7v.png","/map-media/2f56343d8c90da9091bb.png":"https://patchwiki.biligame.com/images/nrc/e/e8/nh3tdv4x07du89bm7l4sd37spmmybun.png","/map-media/5123a8a8b769d8f411c5.png":"https://patchwiki.biligame.com/images/nrc/1/1c/paohiyqd7ppa4mi26u9p72tjm4schif.png","/map-media/75c54b80cd23aed8af3e.png":"https://patchwiki.biligame.com/images/nrc/c/cc/335bszu7qej4ut77woao0gqfsuxep62.png","/map-media/a4bfc3352acdfaa581b7.png":"https://patchwiki.biligame.com/images/nrc/9/9c/bt3hg6l750lxk7aqhboswhi22aolvsd.png","/map-media/b736389b32b184d9323f.png":"https://patchwiki.biligame.com/images/nrc/d/d7/gmjg8ryfrkrftfjpvpz9wq65wungdle.png","/map-media/af370e0fe4c0eb81a558.png":"https://patchwiki.biligame.com/images/nrc/2/21/kkh0vv6fahh42680gbh2fv9t2fu7f3e.png","/map-media/af94200d5a43ae97b510.png":"https://patchwiki.biligame.com/images/nrc/0/0c/1174du34254183wt9lxyu2e6ye52biu.png","/map-media/6f0655834e9f2e5196f4.png":"https://patchwiki.biligame.com/images/nrc/9/91/emzwrg02wcnpnr80cnjp9xp0j4cg7re.png","/map-media/e8d3a4a6e332f1be7130.png":"https://patchwiki.biligame.com/images/nrc/e/ee/ryf89o9x16x97w9jevvzwkcy2h0pyor.png","/map-media/370998f7f75d4131b5be.png":"https://patchwiki.biligame.com/images/nrc/3/36/fe0ovmsc399kgo9n9fey5thg0ukg3c9.png","/map-media/33955e165b226bc467f9.png":"https://patchwiki.biligame.com/images/nrc/b/b3/m4fh806y2leqqq859pbbxk0g825xysf.png","/map-media/5e9162bc2b8272091e0c.png":"https://patchwiki.biligame.com/images/nrc/1/1f/mwcaloo2ibb74w6g6wf9pq5xa5otwyt.png","/map-media/db02d24d6454f8da109c.png":"https://patchwiki.biligame.com/images/nrc/f/fa/qm0yslg9v2dldklq240lv9ulvg91yxm.png","/map-media/492cce2061893f7bb2a1.png":"https://patchwiki.biligame.com/images/nrc/1/13/fndx600n7tz1ilo54zmm6pozm6ug507.png","/map-media/c2b6ac35659e09b67e88.png":"https://patchwiki.biligame.com/images/nrc/0/04/8udeq2ayil2szqxy8fkj384om71k1a9.png","/map-media/77edf69dc46ac1a08b07.png":"https://patchwiki.biligame.com/images/nrc/8/81/o1cu9ar86qsnw2woj12ogxockykecht.png","/map-media/72860efa83cf8e5b6e9e.png":"https://patchwiki.biligame.com/images/nrc/a/a2/gyq24lyuxv7m8pbdnwzfi2rk070998e.png","/map-media/0eb992aa6a9b00fa47c8.png":"https://patchwiki.biligame.com/images/nrc/d/d0/13igty3f38vmq37zgrnp57y7n2t9weh.png","/map-media/ca5ddb57652f25c3c572.png":"https://patchwiki.biligame.com/images/nrc/d/df/egqks7x35tq02z59mcvzjn9j8wayihb.png","/map-media/e83dda28881f9b802d08.png":"https://patchwiki.biligame.com/images/nrc/e/eb/gt94dqhh0nzeh7ekarpm5fubbgxb2af.png","/map-media/7b7da735087584401f3a.png":"https://patchwiki.biligame.com/images/nrc/9/9c/asrrstill2nzqcmjm26vs4i01f4k8p4.png","/map-media/2e1e7f6311083f8e4ed6.png":"https://patchwiki.biligame.com/images/nrc/1/15/kzvbfuhlu8e9e90zajcao99j8pso0w2.png","/map-media/bbb3101e3b0af1538d43.png":"https://patchwiki.biligame.com/images/nrc/7/71/7bgy6se085u0cypq6p5v9bsfip7isq6.png","/map-media/832d184b4137de245d2a.png":"https://patchwiki.biligame.com/images/nrc/b/b1/b0qso7ati95yqy8rcy1ru7v35ufetsp.png","/map-media/a1ae5e9ec3174b69efb5.png":"https://patchwiki.biligame.com/images/nrc/f/f6/hs07beijwvcfjtdzzf9b8j84msjf6x7.png","/map-media/4f2a31d3f0bb146f8952.png":"https://patchwiki.biligame.com/images/nrc/0/04/ehs3jwmt4k83troskky1316dfi5piwm.png","/map-media/bd6534185605daf5d8d4.png":"https://patchwiki.biligame.com/images/nrc/4/41/exuaacfnt3hyo36gd8yutnf9bwikp6t.png","/map-media/94d358b4fc6619c9766b.png":"https://patchwiki.biligame.com/images/nrc/9/9e/8kzmf46m3s6uueyhhjm43cwga73q6d7.png","/map-media/ecdbe905cfaf6cf7567d.png":"https://patchwiki.biligame.com/images/nrc/e/e8/t0hs7ii4osfu3cj16nvjzmxlrvccyph.png","/map-media/d8b2af66285be4832c46.png":"https://patchwiki.biligame.com/images/nrc/8/80/b4px7dqq7cev9au65ue4ts8mycas7q6.png","/map-media/06a9f98484d974da9236.png":"https://patchwiki.biligame.com/images/nrc/8/8d/omje2p243lubhb1i2lop6k56onhqjsx.png","/map-media/ae3835a97b5e42262a20.png":"https://patchwiki.biligame.com/images/nrc/d/d1/0p1chxuwyp6whd1e9b8cbuxvthv4rlf.png","/map-media/025fc45a47b70054b6be.png":"https://patchwiki.biligame.com/images/nrc/5/58/4olfq3klu554a5nlwht0n3k3zo1lw9t.png","/map-media/b5e593c8f81c8511fa3f.png":"https://patchwiki.biligame.com/images/nrc/d/dc/263rdorwzkdq0patsjnfne7gkm2fzt7.png","/map-media/578dc6a9440bb35bf1e9.png":"https://patchwiki.biligame.com/images/nrc/2/23/gau7cmpwz41giera5fu8v6ijviq7byx.png","/map-media/04cb7a44e177d5bbb77a.png":"https://patchwiki.biligame.com/images/nrc/3/36/js1fv1mulqc87vx842tob9qykfkkisl.png","/map-media/2d05692c3dc057921dfd.png":"https://patchwiki.biligame.com/images/nrc/8/86/p5t4obeabgrlk4ejx3i9lu4jblqzvia.png","/map-media/23e217521e58bc9e9b8c.png":"https://patchwiki.biligame.com/images/nrc/c/ca/b4xc4pae9k8editmhl1z3he7uf64djm.png","/map-media/e8611d39f2bb1fa87d14.png":"https://patchwiki.biligame.com/images/nrc/0/0b/7z7s9jabenpysbj78fdk4c6rf7kkl0j.png","/map-media/d25d4383c2ad95fd835d.png":"https://patchwiki.biligame.com/images/nrc/2/20/ohqc1h1rtq13awy5tnv94dlew4vw6u0.png","/map-media/27ac89d1d36cff79a1fc.png":"https://patchwiki.biligame.com/images/nrc/8/82/3hd3rww0l0426mz5igrf0qbvnn5z9as.png","/map-media/2141e1ceaeb5cb79f2a0.png":"https://patchwiki.biligame.com/images/nrc/c/c8/8aotsy4yvjl3b2b5w40buux3cgyh5sl.png","/map-media/968660d5be15ee185de5.png":"https://patchwiki.biligame.com/images/nrc/e/e9/j5pnvovd65al32tr6nic6v6rk18snly.png","/map-media/13076f64cbf2b5cbc7e9.png":"https://patchwiki.biligame.com/images/nrc/5/5d/oquv9txul6fk2k51nwuvnpefed5akar.png","/map-media/9325a4ca8e4337475402.png":"https://patchwiki.biligame.com/images/nrc/8/8e/2mfivvah9vq1v8gg8tlp5v2v3u38d1w.png","/map-media/5b40044ec8f67f372976.png":"https://patchwiki.biligame.com/images/nrc/8/86/erb0uc5jphtabdyf4tlhi7rtjxrez6d.png","/map-media/557a09a6900e86a9e5a2.png":"https://patchwiki.biligame.com/images/nrc/6/63/1m2hpf24di432dbs4d49pgybwu51m1d.png","/map-media/85c13492d39a7db54e5c.png":"https://patchwiki.biligame.com/images/nrc/4/44/alak0swokml85yowimujfn51bk5hrfx.png","/map-media/ac9d56c691cf0152406a.png":"https://patchwiki.biligame.com/images/nrc/4/46/t45accan3l1fdlkjs04f3jllj22iems.png","/map-media/ee39e976708aadce64de.png":"https://patchwiki.biligame.com/images/nrc/9/90/8z7ynrvwp7tn9bg3z6w2kmcrfsppqlp.png","/map-media/cd89ed8c67e49fda6f88.png":"https://patchwiki.biligame.com/images/nrc/7/75/3dzmnm4a4vaqu46blk5vjvsq6n34u8b.png","/map-media/3d2f58bcb24b4fb17c07.png":"https://patchwiki.biligame.com/images/nrc/0/0a/c5j12wnk8bfggugkjx260zo1okmtm6k.png","/map-media/eb3babde10dd75562111.png":"https://patchwiki.biligame.com/images/nrc/4/40/rnk49fp6qxwnzqr6y43o7532j0is65l.png","/map-media/ed5b5caff1e1d98ad2f0.png":"https://patchwiki.biligame.com/images/nrc/2/28/s5m88geol4ppbidjmb11iwou22sehys.png","/map-media/14f1f301d5dc10fde855.png":"https://patchwiki.biligame.com/images/nrc/8/86/p5t4obeabgrlk4ejx3i9lu4jblqzvia.png","/map-media/f7160cf3b1c679f886b9.png":"https://patchwiki.biligame.com/images/nrc/b/be/jzyiaegnpvjuvvlawmhcefe2dugjx5v.png","/map-media/43d433b827aaabc09f84.png":"https://patchwiki.biligame.com/images/nrc/9/98/p4tstoxxkcq2j7gl556pgm6ijskj5wt.png","/map-media/6ba73a74836ce2ff5721.png":"https://patchwiki.biligame.com/images/nrc/b/b1/b6s8pns3yr2hszcg0rjmzp61yhev1ua.png","/map-media/3852da8a5993ea58bf1b.png":"https://patchwiki.biligame.com/images/nrc/4/44/i8j8ihg5k1rn8yv8r4bsti1e1qvd4uz.png","/map-media/333f1577fc7ef6bf2455.png":"https://patchwiki.biligame.com/images/nrc/8/85/4uzh2kbyz233chpkniawfk4hi3n6107.png","/map-media/e025a459b7f92f571f96.png":"https://patchwiki.biligame.com/images/nrc/6/65/1bjjntsooni3fvkive69j67ngtdv0ph.png","/map-media/67f04bbda74ba2906541.png":"https://patchwiki.biligame.com/images/nrc/6/6c/qrjuts8jpc4vyn57pfp19pocmr8bjgs.png","/map-media/b412fe9c9b8a256cca1a.png":"https://patchwiki.biligame.com/images/nrc/8/87/p5iqn2ymbvrm6qipm2uer0u1m9d3r6g.png","/map-media/2b81bf132c608fa72e1c.png":"https://patchwiki.biligame.com/images/nrc/8/89/9i95t4879fqejkxlmgwbsqmhg8hatw7.png","/map-media/ffbbaecf98ac25438740.png":"https://patchwiki.biligame.com/images/nrc/f/fa/oefrw1hfgyr9f0gzu9ombhoshkrcs80.png","/map-media/fd127ad10e48042b288b.png":"https://patchwiki.biligame.com/images/nrc/d/d3/38efcjhn6ip7c2nn57us0nwu23btff8.png","/map-media/4a2bdb7bbe531cfd6d67.png":"https://patchwiki.biligame.com/images/nrc/8/88/froimapkcy24qi30lkq20scsldwhin9.png","/map-media/tiles-c91ebf8e8d874eae1ba0/01.png":"https://patchwiki.biligame.com/images/nrc/0/0f/i6cv0dztg1wfgu9isupa57huf7tvdip.png","/map-media/tiles-c91ebf8e8d874eae1ba0/02.png":"https://patchwiki.biligame.com/images/nrc/3/3f/h1a2tdv7eyozxxut42wktdqp7gjwjbw.png","/map-media/tiles-c91ebf8e8d874eae1ba0/03.png":"https://patchwiki.biligame.com/images/nrc/9/91/rrpqmfi185v99pfgqas8we8vtsfisjy.png","/map-media/tiles-c91ebf8e8d874eae1ba0/04.png":"https://patchwiki.biligame.com/images/nrc/9/98/nptbr3rfqnjbp4y4ctjsht45y9iae6t.png","/map-media/tiles-c91ebf8e8d874eae1ba0/05.png":"https://patchwiki.biligame.com/images/nrc/8/85/04w7sewl4fo6fwp05tmdmjweojlj1te.png","/map-media/tiles-c91ebf8e8d874eae1ba0/06.png":"https://patchwiki.biligame.com/images/nrc/b/bc/dmq982gpt58m7h4h3zoxcm0bfo7dl8y.png","/map-media/tiles-c91ebf8e8d874eae1ba0/07.png":"https://patchwiki.biligame.com/images/nrc/4/41/2qw2nnz2u72eorv8uknsjkdtmkkru6p.png","/map-media/tiles-c91ebf8e8d874eae1ba0/08.png":"https://patchwiki.biligame.com/images/nrc/2/20/qixn5yod9q25qt2ee1z1u85h5s2ef53.png","/map-media/tiles-c91ebf8e8d874eae1ba0/09.png":"https://patchwiki.biligame.com/images/nrc/3/30/3rfofqdawv6zv8u4gv40dpgv9v94kme.png","/map-media/tiles-c91ebf8e8d874eae1ba0/10.png":"https://patchwiki.biligame.com/images/nrc/3/30/ffof01cu1olydms7zimk3zaqtsb68r3.png","/map-media/tiles-c91ebf8e8d874eae1ba0/11.png":"https://patchwiki.biligame.com/images/nrc/b/bf/dkwvqvqov0ewkxhfk3asz877vpmofzh.png","/map-media/tiles-c91ebf8e8d874eae1ba0/12.png":"https://patchwiki.biligame.com/images/nrc/d/d3/h3tzh0tu63oq8tx6sdhp28kkdxwhf3b.png","/map-media/tiles-c91ebf8e8d874eae1ba0/13.png":"https://patchwiki.biligame.com/images/nrc/e/ea/if9hx1wlhlcjbykkpztis7oqfg0wa7b.png","/map-media/tiles-c91ebf8e8d874eae1ba0/14.png":"https://patchwiki.biligame.com/images/nrc/2/26/c0umhhysfn85uvglliggj7ucq3skl45.png","/map-media/tiles-c91ebf8e8d874eae1ba0/15.png":"https://patchwiki.biligame.com/images/nrc/7/73/0txzmdu0g1lz9pj7gj9rbidopkfdch4.png","/map-media/tiles-c91ebf8e8d874eae1ba0/16.png":"https://patchwiki.biligame.com/images/nrc/0/03/lofuinethpoigiocsfzfmql6sbd2thw.png","/map-media/tiles-9382aa703ef339597cd0/01.png":"https://patchwiki.biligame.com/images/nrc/3/39/5a7ao5legnssswkmsdtt5zn3bzkvqlg.png","/map-media/tiles-9382aa703ef339597cd0/02.png":"https://patchwiki.biligame.com/images/nrc/d/d6/2flpg3asag528h5t32of707qehs9h60.png","/map-media/tiles-9382aa703ef339597cd0/03.png":"https://patchwiki.biligame.com/images/nrc/3/39/es06r1guresdiyrkvwtegzkskhfswv0.png","/map-media/tiles-9382aa703ef339597cd0/04.png":"https://patchwiki.biligame.com/images/nrc/a/a1/olspi17grldoikeg550krv4nsazuzyj.png","/map-media/tiles-9382aa703ef339597cd0/05.png":"https://patchwiki.biligame.com/images/nrc/0/0e/osttz2vlr4n12n1hoaije3hdwbkfywq.png","/map-media/tiles-9382aa703ef339597cd0/06.png":"https://patchwiki.biligame.com/images/nrc/2/2c/a7iqrgyr8p8r58963acm3c23wwyq4q7.png","/map-media/tiles-9382aa703ef339597cd0/07.png":"https://patchwiki.biligame.com/images/nrc/0/02/tjico3u0rg2fomkh0j14sclk5pd0lj1.png","/map-media/tiles-9382aa703ef339597cd0/08.png":"https://patchwiki.biligame.com/images/nrc/d/d8/j0x9gtq80e8wbfte9bdm10ou7zynf71.png","/map-media/tiles-9382aa703ef339597cd0/09.png":"https://patchwiki.biligame.com/images/nrc/3/33/kei7twbzjpsme7i7us2ajwznik52f3r.png","/map-media/tiles-9382aa703ef339597cd0/10.png":"https://patchwiki.biligame.com/images/nrc/d/d3/cjmum96uqw6c6fvgcntwl0tkvz1izfl.png","/map-media/tiles-9382aa703ef339597cd0/11.png":"https://patchwiki.biligame.com/images/nrc/0/08/0vvpqvas9rrtp2lejimwga6errsm7xr.png","/map-media/tiles-9382aa703ef339597cd0/12.png":"https://patchwiki.biligame.com/images/nrc/f/f8/6xqx9xbkkm31r090f4hykyorq3xzd0k.png","/map-media/tiles-9382aa703ef339597cd0/13.png":"https://patchwiki.biligame.com/images/nrc/0/0f/a8sw7bnm6jkeu1fac5zunfq81cbgb4e.png","/map-media/tiles-9382aa703ef339597cd0/14.png":"https://patchwiki.biligame.com/images/nrc/8/85/0hf32ai648zvv5qqmer0rugkycuna4v.png","/map-media/tiles-9382aa703ef339597cd0/15.png":"https://patchwiki.biligame.com/images/nrc/b/b4/pkmljwumj39kloc4n6ecq6ey7wrl2bg.png","/map-media/tiles-9382aa703ef339597cd0/16.png":"https://patchwiki.biligame.com/images/nrc/e/e3/72fh8u66ucd1vyodv88zps13cajm8wv.png","/map-media/tiles-956d752d74a8ebd9b8a8/01.png":"https://patchwiki.biligame.com/images/nrc/0/02/jf639l70jikipebkt94g20tz0iw7vcm.png","/map-media/tiles-956d752d74a8ebd9b8a8/02.png":"https://patchwiki.biligame.com/images/nrc/9/9b/hiflmtrxru4ee08vysv17hwxxylj280.png","/map-media/tiles-956d752d74a8ebd9b8a8/03.png":"https://patchwiki.biligame.com/images/nrc/9/98/ek3rlx6hf4w8aww9680w5zsikgjrykj.png","/map-media/tiles-956d752d74a8ebd9b8a8/04.png":"https://patchwiki.biligame.com/images/nrc/b/b7/odckc5z3x14hzigy7yl2dptsqf2698w.png","/map-media/tiles-956d752d74a8ebd9b8a8/05.png":"https://patchwiki.biligame.com/images/nrc/9/9d/ic28kg3m8p4wvp6nxxw26uc7gkgkpe6.png","/map-media/tiles-956d752d74a8ebd9b8a8/06.png":"https://patchwiki.biligame.com/images/nrc/c/cf/lhsunfmhyi2259jtjaorl6sz9zww9uw.png","/map-media/tiles-956d752d74a8ebd9b8a8/07.png":"https://patchwiki.biligame.com/images/nrc/e/e4/t0p56sku5houud1ypyf37kgf91qbe0n.png","/map-media/tiles-956d752d74a8ebd9b8a8/08.png":"https://patchwiki.biligame.com/images/nrc/c/c6/cthtr6inu16jadrw47tyxi7n6t04qnm.png","/map-media/tiles-956d752d74a8ebd9b8a8/09.png":"https://patchwiki.biligame.com/images/nrc/1/1b/on87l4ahuxkdjzmzpl9y3vop32du1a6.png","/map-media/tiles-956d752d74a8ebd9b8a8/10.png":"https://patchwiki.biligame.com/images/nrc/1/1d/e5bltbwz92hghppi842y9kalo2tqgue.png","/map-media/tiles-956d752d74a8ebd9b8a8/11.png":"https://patchwiki.biligame.com/images/nrc/f/f7/isdnb215c2nhzqlwihd6b1kh7ih8uz4.png","/map-media/tiles-956d752d74a8ebd9b8a8/12.png":"https://patchwiki.biligame.com/images/nrc/9/92/elouv99nfr5j4l19r93149eht6c5m7r.png","/map-media/tiles-956d752d74a8ebd9b8a8/13.png":"https://patchwiki.biligame.com/images/nrc/e/ed/bnd0bmdh3yvam9ya7hr29bn3wu1glqx.png","/map-media/tiles-956d752d74a8ebd9b8a8/14.png":"https://patchwiki.biligame.com/images/nrc/3/3f/trok1iswagaeqsxs882441c5qq07u5n.png","/map-media/tiles-956d752d74a8ebd9b8a8/15.png":"https://patchwiki.biligame.com/images/nrc/3/3c/qy990k3kdvxyo1mp2547i6f2s197067.png","/map-media/tiles-956d752d74a8ebd9b8a8/16.png":"https://patchwiki.biligame.com/images/nrc/a/a4/8m6dct2fbvqw4nk8tadcpjicqlp8uvq.png","/map-media/tiles-e78695d3b45bf4398d96/01.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/02.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/03.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/04.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/05.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/06.png":"https://patchwiki.biligame.com/images/nrc/1/16/kmigj4ukph11ip20hsbjmpxn19szjmq.png","/map-media/tiles-e78695d3b45bf4398d96/07.png":"https://patchwiki.biligame.com/images/nrc/5/57/gc85ql3ty9imowym7y8b8vkhnadll9x.png","/map-media/tiles-e78695d3b45bf4398d96/08.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/09.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/10.png":"https://patchwiki.biligame.com/images/nrc/7/74/d7hc4updacdw9uvach0d2qo71zl4xlr.png","/map-media/tiles-e78695d3b45bf4398d96/11.png":"https://patchwiki.biligame.com/images/nrc/b/ba/hwgmci4s1ee0orwaxq5vjx389ro8q8z.png","/map-media/tiles-e78695d3b45bf4398d96/12.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/13.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-e78695d3b45bf4398d96/14.png":"https://patchwiki.biligame.com/images/nrc/8/8d/fcjrfu85hqpiaww56fxgaqugf6c4ahe.png","/map-media/tiles-e78695d3b45bf4398d96/15.png":"https://patchwiki.biligame.com/images/nrc/f/f0/mvtz5yz9q69iqxhmtp6run7cq0r4gcp.png","/map-media/tiles-e78695d3b45bf4398d96/16.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/01.png":"https://patchwiki.biligame.com/images/nrc/1/15/n20xqljmgcm9n2vdfzcpo8fbkkl8fuz.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/02.png":"https://patchwiki.biligame.com/images/nrc/6/66/2smrnomlyruekl91dupr4ym88cpe0wv.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/03.png":"https://patchwiki.biligame.com/images/nrc/3/3f/mnxnlxp9aep8okk0ztswq6bbum4yva8.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/04.png":"https://patchwiki.biligame.com/images/nrc/c/c3/1r0rp7o7es1fc356t4bpwo170tcdw94.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/05.png":"https://patchwiki.biligame.com/images/nrc/7/7a/avj64q0ad8cgu6990eao1vsvoy15d3x.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/06.png":"https://patchwiki.biligame.com/images/nrc/1/12/dyat8vmas82dnhyp6bkq41nnzk9quvz.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/07.png":"https://patchwiki.biligame.com/images/nrc/d/d5/466uspjqbcqvdrzt3w0endsry29uxww.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/08.png":"https://patchwiki.biligame.com/images/nrc/f/f2/mevdeyrzhzkbpi88xcgc2noh0sk3lqv.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/09.png":"https://patchwiki.biligame.com/images/nrc/4/47/bteaxf7gw52zvnmixtq6sqa32jq2a3v.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/10.png":"https://patchwiki.biligame.com/images/nrc/0/0e/qusvvfonpgh0c0d7agrk7yoj86ayjvn.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/11.png":"https://patchwiki.biligame.com/images/nrc/e/eb/s311d3r7glfglzyvssn69086fz67185.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/12.png":"https://patchwiki.biligame.com/images/nrc/a/ac/0yephlete8acwyu980f6bsshnis86pt.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/13.png":"https://patchwiki.biligame.com/images/nrc/3/33/omomfhhvotge10kuvj6f4zekn6essdu.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/14.png":"https://patchwiki.biligame.com/images/nrc/d/da/m3el9i11xzav5b6008qf0iy2uclbw1t.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/15.png":"https://patchwiki.biligame.com/images/nrc/6/64/8xynpby2j4ewwavvcn4vxrfq6abqaa7.png","/map-media/tiles-5cc0ec0bf3e42fdc9314/16.png":"https://patchwiki.biligame.com/images/nrc/9/93/59knaytt0jhc4xdpgwj4elpdts5m6su.png","/map-media/tiles-fc182847a7daff3aeccb/01.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/02.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/03.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/04.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/05.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/06.png":"https://patchwiki.biligame.com/images/nrc/5/5e/ix8dis72xezrjgtwls3vedsqxnc2amv.png","/map-media/tiles-fc182847a7daff3aeccb/07.png":"https://patchwiki.biligame.com/images/nrc/f/f5/1nq5l369b9at8w0gpi31e7d9435004o.png","/map-media/tiles-fc182847a7daff3aeccb/08.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/09.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/10.png":"https://patchwiki.biligame.com/images/nrc/0/0f/cagium7cwh1p59ga2gzj28f6yzly4gf.png","/map-media/tiles-fc182847a7daff3aeccb/11.png":"https://patchwiki.biligame.com/images/nrc/f/fa/46knbd2dpebbpro1wo4t1apjt1rng8m.png","/map-media/tiles-fc182847a7daff3aeccb/12.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/13.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/tiles-fc182847a7daff3aeccb/14.png":"https://patchwiki.biligame.com/images/nrc/6/61/th2i92halyycu83qq084fnxdjlxgzgb.png","/map-media/tiles-fc182847a7daff3aeccb/15.png":"https://patchwiki.biligame.com/images/nrc/7/75/gr2hysk5xqn95b1lk37qm89d2lb234c.png","/map-media/tiles-fc182847a7daff3aeccb/16.png":"https://patchwiki.biligame.com/images/nrc/9/96/rhn9uy3f5fald2yz8kob0pdcxqwpy31.png","/map-media/bd3e1d29024ef5802494.png":"https://patchwiki.biligame.com/images/nrc/9/9e/ncyick9sviu9sxaukwka62n57i4eunz.png","/map-media/26319d118832314c50cd.png":"https://patchwiki.biligame.com/images/nrc/8/8a/gyxmxamuw5gfz2sjvol918x0wznu6dw.png","/map-media/f67e913dce402a7730d6.png":"https://patchwiki.biligame.com/images/nrc/a/a3/1szfvc3yu7b8doi0xom51oi9yiswjir.png","/map-media/956fafd065c98f78df20.png":"https://patchwiki.biligame.com/images/nrc/9/96/j7s0vy3mkjheudc1qmdqeeuyom6z81j.png","/map-media/901403b8459735c0ecde.png":"https://patchwiki.biligame.com/images/nrc/e/e6/lqzm0z2lbutteuzdfzfp28hm25b5g3g.png","/map-media/ca96e300f158a1a13c10.png":"https://patchwiki.biligame.com/images/nrc/e/e9/acq85ujlx5ehjyzm4jmpoa6g1eaqxpm.png","/map-media/a34e03e196dc3abe5d5b.png":"https://patchwiki.biligame.com/images/nrc/1/19/cdsvi4j4e7hmuzqxa9ujbjijxhtd597.png","/map-media/82069e986f34ae8c73d7.png":"https://patchwiki.biligame.com/images/nrc/0/05/645b79b1bb1jnzojorliv409rdhdzjt.png","/map-media/89573b9f9edf0b6b59d3.png":"https://patchwiki.biligame.com/images/nrc/0/05/645b79b1bb1jnzojorliv409rdhdzjt.png","/map-media/ba7fa1b8d823798deaa2.png":"https://patchwiki.biligame.com/images/nrc/c/ca/14v9n55dy441t07b2yjkg0uaj51x1w0.png","/map-media/6ce2641f17df1728439b.png":"https://patchwiki.biligame.com/images/nrc/c/ca/14v9n55dy441t07b2yjkg0uaj51x1w0.png","/map-media/54d02c83d4b7d8fed6b7.png":"https://patchwiki.biligame.com/images/nrc/0/02/ozh07z184ubr37il3jyfigij72gkqgq.png","/map-media/8f465047c8acd4cafda3.png":"https://patchwiki.biligame.com/images/nrc/0/02/ozh07z184ubr37il3jyfigij72gkqgq.png","/map-media/171d8967f242cdb66888.png":"https://patchwiki.biligame.com/images/nrc/1/16/s8ai2ttausck8e3hma81zhx2inbwedr.png","/map-media/eaaa3b1608ff0cf08392.png":"https://patchwiki.biligame.com/images/nrc/1/16/s8ai2ttausck8e3hma81zhx2inbwedr.png","/map-media/f0b608ec3fdc8db2fe90.png":"https://patchwiki.biligame.com/images/nrc/5/56/9dhdi9e6sn89wczkpq8fnhwhlyrfezy.png","/map-media/5928388d6cdaa9260048.png":"https://patchwiki.biligame.com/images/nrc/5/56/9dhdi9e6sn89wczkpq8fnhwhlyrfezy.png","/map-media/277ba5329f1213d95549.png":"https://patchwiki.biligame.com/images/nrc/f/fd/kyegm4psi4jjlqplntyuejk70wz6wy3.png","/map-media/6da4f01f4346f5897a60.png":"https://patchwiki.biligame.com/images/nrc/0/06/kjjzn1z7k1rvtjb4570lq8lqho3f3x4.png","/map-media/2f2d60e1bfd89b0373af.png":"https://patchwiki.biligame.com/images/nrc/e/e6/k40us419y0231q5mdy1236kmgtbaz83.png","/map-media/e6fd536d1a64b6a5a301.png":"https://patchwiki.biligame.com/images/nrc/5/5e/i5ys2axvd3m99fxm1b46e0siuwgrc4n.png","/map-media/f657f550a6d72db662c5.png":"https://patchwiki.biligame.com/images/nrc/c/c8/733bl3k24i7nbkzzoxwbnjubjvp12pw.png","/map-media/aaf12989606c6dc7593c.png":"https://patchwiki.biligame.com/images/nrc/0/07/4dbplzfq7029dylrmlbbxqcwz3b8f8x.png","/map-media/3361522b305b61200f90.png":"https://patchwiki.biligame.com/images/nrc/3/34/hhzbyay1sv73jbc8t3a1hiji98f1uwy.png","/map-media/d45629f095c70ede0315.png":"https://patchwiki.biligame.com/images/nrc/8/8a/gc3mqslqts4uy4da12yrtuae9wg9i72.png","/map-media/ba1c3c70b1ff059cab60.png":"https://patchwiki.biligame.com/images/nrc/7/7c/d62hfic7eggeyat6sglz7992fot2fjx.png","/map-media/020f9c0982a8f323e5d0.png":"https://patchwiki.biligame.com/images/nrc/4/4d/fjynbm2de455qysr8s383zih3mue3cl.png"},"data":{"/map-data/mainland/map-core.json":["MediaWiki:WorldMap/data/mainland-map-core-1.js","MediaWiki:WorldMap/data/mainland-map-core-2.js","MediaWiki:WorldMap/data/mainland-map-core-3.js","MediaWiki:WorldMap/data/mainland-map-core-4.js","MediaWiki:WorldMap/data/mainland-map-core-5.js","MediaWiki:WorldMap/data/mainland-map-core-6.js","MediaWiki:WorldMap/data/mainland-map-core-7.js","MediaWiki:WorldMap/data/mainland-map-core-8.js","MediaWiki:WorldMap/data/mainland-map-core-9.js","MediaWiki:WorldMap/data/mainland-map-core-10.js"],"/map-data/mainland/map-points.json":["MediaWiki:WorldMap/data/mainland-map-points-1.js","MediaWiki:WorldMap/data/mainland-map-points-2.js","MediaWiki:WorldMap/data/mainland-map-points-3.js","MediaWiki:WorldMap/data/mainland-map-points-4.js","MediaWiki:WorldMap/data/mainland-map-points-5.js","MediaWiki:WorldMap/data/mainland-map-points-6.js"],"/map-data/academy/map-core.json":["MediaWiki:WorldMap/data/academy-map-core-1.js","MediaWiki:WorldMap/data/academy-map-core-2.js"],"/map-data/academy/map-points.json":["MediaWiki:WorldMap/data/academy-map-points-1.js"]},"dataVersions":{"MediaWiki:WorldMap/data/mainland-map-core-1.js":"1b86801405728092","MediaWiki:WorldMap/data/mainland-map-core-2.js":"ed14f059b41eb705","MediaWiki:WorldMap/data/mainland-map-core-3.js":"eb9eb7676ccee7bc","MediaWiki:WorldMap/data/mainland-map-core-4.js":"35724be49a693193","MediaWiki:WorldMap/data/mainland-map-core-5.js":"8bd0d65a917dd9a6","MediaWiki:WorldMap/data/mainland-map-core-6.js":"cfff2125ff5d89f5","MediaWiki:WorldMap/data/mainland-map-core-7.js":"8e8e121b10a0b85b","MediaWiki:WorldMap/data/mainland-map-core-8.js":"95672c00d111617f","MediaWiki:WorldMap/data/mainland-map-core-9.js":"c7ec92e1a48ecd2e","MediaWiki:WorldMap/data/mainland-map-core-10.js":"6db12a4a44ad62d8","MediaWiki:WorldMap/data/mainland-map-points-1.js":"93d925828648c6ab","MediaWiki:WorldMap/data/mainland-map-points-2.js":"3bb05b0ad099fa57","MediaWiki:WorldMap/data/mainland-map-points-3.js":"6e4e5961bf005f95","MediaWiki:WorldMap/data/mainland-map-points-4.js":"0ac19d13d0eb5b0f","MediaWiki:WorldMap/data/mainland-map-points-5.js":"b143d2dcc109ddab","MediaWiki:WorldMap/data/mainland-map-points-6.js":"53c1e7f10f74dfc7","MediaWiki:WorldMap/data/academy-map-core-1.js":"28a2bd1e127e9615","MediaWiki:WorldMap/data/academy-map-core-2.js":"de24614acac2cb54","MediaWiki:WorldMap/data/academy-map-points-1.js":"9140485aafa58407"}};
  const allowedPages = new Set(Object.values(config.data).flat());
  const rawUrl = title => {
    if (window.NrcWorldMapPreview) return window.NrcWorldMapPreview.pages[title];
    return (mw.config.get("wgScriptPath") || "/nrc") + "/index.php?" + new URLSearchParams({title, action:"raw", ctype:"text/javascript", v:config.dataVersions[title]});
  };
  function loadPage(title) {
    if (!loads.has(title)) loads.set(title, new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = rawUrl(title);
      const fail = () => { loads.delete(title); payloads.delete(title); decoded.delete(title); script.remove(); reject(new Error("地图资料暂时无法加载，请刷新重试。")); };
      script.onload = () => { script.remove(); if (payloads.has(title)) resolve(); else fail(); };
      script.onerror = fail;
      document.head.append(script);
    }));
    return loads.get(title);
  }
  function assetUrl(path) {
    if (window.NrcWorldMapPreview) return path;
    if (config.assetUrls[path]) return config.assetUrls[path];
    const title = config.assets[path];
    if (!title) throw new Error("地图图片未列入发布清单。");
    const articlePath = mw.config.get("wgArticlePath") || "/nrc/$1";
    return articlePath.replace("$1", encodeURIComponent("Special:Redirect/file/" + title).replace(/%2F/g, "/"));
  }
  async function decodePage(title) {
    if (!decoded.has(title)) decoded.set(title, (async () => {
      const encoded = payloads.get(title);
      if (typeof encoded !== "string" || !encoded.startsWith("gz1:")) throw new Error("地图资料格式不完整。");
      const bytes = Uint8Array.from(atob(encoded.slice(4)), char => char.charCodeAt(0));
      const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
      const value = JSON.parse(await new Response(stream).text());
      payloads.delete(title);
      return value;
    })().catch(error => {
      decoded.delete(title); loads.delete(title); payloads.delete(title);
      throw error;
    }));
    return decoded.get(title);
  }
  async function wikiData(path) {
    const titles = config.data[path];
    if (!titles) throw new Error("地图资料未列入发布清单。");
    await Promise.all(titles.map(loadPage));
    const parts = await Promise.all(titles.map(decodePage));
    if (path.endsWith("map-points.json")) return {points:parts.flat()};
    const [core, ...details] = parts;
    return {...core, details:Object.assign({}, ...details)};
  }
  function mount(root) {
    if (root.dataset.mapReady) return;
    root.dataset.mapReady = "true";
    root.innerHTML = "\u003cdiv class=\"app-shell\">\n      \u003c!-- map-loading:start -->\n      \u003cdiv class=\"loading-card\" id=\"loading-card\" role=\"status\" aria-live=\"polite\">\n        \u003cdiv class=\"map-loading-content\">\n          \u003cdiv class=\"map-loading-art\" aria-hidden=\"true\">\n            \u003cdiv class=\"map-loading-orbit\">\u003c/div>\n            \u003cdiv class=\"map-loading-paper is-left\">\u003c/div>\n            \u003cdiv class=\"map-loading-paper is-middle\">\u003c/div>\n            \u003cdiv class=\"map-loading-paper is-right\">\u003c/div>\n            \u003cdiv class=\"map-loading-route\">\u003c/div>\n            \u003cdiv class=\"map-loading-pin\">\u003c/div>\n            \u003cdiv class=\"map-loading-compass\">\u003c/div>\n          \u003c/div>\n          \u003cdiv class=\"map-loading-title\" id=\"loading-title\">正在展开地图…\u003c/div>\n          \u003cdiv class=\"map-loading-detail\" id=\"loading-detail\">寻找沿途的风景与精灵\u003c/div>\n          \u003cdiv class=\"map-loading-trail\" aria-hidden=\"true\">\u003cdiv>\u003c/div>\u003cdiv>\u003c/div>\u003cdiv>\u003c/div>\u003c/div>\n        \u003c/div>\n      \u003c/div>\n      \u003c!-- map-loading:end -->\n      \u003cdiv data-nrc-tag=header class=\"topbar\">\n        \u003cdiv class=\"topbar-actions\">\n          \u003cdiv class=\"icon-button\" id=\"wiki-home\" role=\"link\" tabindex=\"0\" aria-label=\"返回 Wiki 首页\" title=\"返回 Wiki 首页\">\u003ci class=\"ui-icon fa-solid fa-house\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n          \u003cdiv data-nrc-tag=button class=\"icon-button\" id=\"layer-toggle\" data-nrc-type=\"button\" aria-label=\"收起筛选\" title=\"点位筛选\" aria-controls=\"layer-panel\" aria-expanded=\"true\">\u003ci class=\"ui-icon fa-solid fa-sliders\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n        \u003c/div>\n        \u003cdiv class=\"brand\" data-nrc-tag=\"button\" aria-label=\"返回全图\">\n          \u003c!-- BWIKI 站点 Logo：RocoWorld_Wiki_Logo_White_Trimmed.png -->\n          \u003cimg class=\"brand-logo\" src=\"https://patchwiki.biligame.com/images/nrc/7/72/69b6hqpwdwl7ulpqsvfh1mo4dihiv09.png\" width=\"606\" height=\"109\" alt=\"洛克王国世界 WIKI\" />\n        \u003c/div>\n        \u003cdiv class=\"search-box\">\n          \u003ci class=\"ui-icon search-icon fa-solid fa-magnifying-glass\" aria-hidden=\"true\">\u003c/i>\n          \u003cinput id=\"global-search\" type=\"search\" autocomplete=\"off\" placeholder=\"找精灵、宝箱、地点…\" aria-label=\"搜索所有点位，不受当前筛选限制\" role=\"combobox\" aria-autocomplete=\"list\" aria-controls=\"search-results\" aria-expanded=\"false\" />\n          \u003ckbd>/\u003c/kbd>\n          \u003cdiv class=\"search-results\" id=\"search-results\" role=\"listbox\" aria-label=\"匹配点位\" hidden>\u003c/div>\n        \u003c/div>\n        \u003cdiv data-nrc-tag=label class=\"map-switcher\">\n          \u003cspan>地图\u003c/span>\n          \u003cselect id=\"map-select\" aria-label=\"切换地图\">\n            \u003coption value=\"mainland\">卡洛西亚大陆\u003c/option>\n            \u003coption value=\"academy\">魔法学院\u003c/option>\n          \u003c/select>\n        \u003c/div>\n      \u003c/div>\n\n      \u003cdiv data-nrc-tag=aside class=\"layer-panel\" id=\"layer-panel\" aria-label=\"点位筛选\">\n        \u003cdiv class=\"panel-heading\">\n          \u003cdiv>\u003cdiv data-nrc-tag=h2>想找些什么？\u003c/div>\u003cp>选一种探索方式，再挑具体点位。\u003c/p>\u003c/div>\n          \u003cdiv data-nrc-tag=button class=\"icon-button\" id=\"layer-close\" data-nrc-type=\"button\" aria-label=\"收起筛选\">\u003ci class=\"ui-icon fa-solid fa-xmark\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n        \u003c/div>\n        \u003cdiv class=\"panel-scroll\">\n        \u003cdiv class=\"collection-panel\" id=\"collection-panel\">\n          \u003cdiv class=\"collection-heading\">\u003cdiv id=\"collection-progress\">收集进度\u003c/div>\u003cdiv role=\"button\" tabindex=\"0\" data-nrc-tag=\"button\" id=\"collection-types\">可收集点位\u003ci class=\"fa-solid fa-arrow-right\" aria-hidden=\"true\">\u003c/i>\u003c/div>\u003c/div>\n          \u003cdiv class=\"collection-status\" id=\"collection-status\" role=\"status\">登录后记录收集进度\u003c/div>\n          \u003cdiv class=\"collection-account-actions\">\u003cdiv role=\"button\" tabindex=\"0\" data-nrc-tag=\"button\" id=\"collection-login\">\u003ci class=\"fa-solid fa-user\" aria-hidden=\"true\">\u003c/i>登录\u003c/div>\u003cdiv role=\"button\" tabindex=\"0\" data-nrc-tag=\"button\" id=\"collection-retry\" hidden>\u003ci class=\"fa-solid fa-rotate-right\" aria-hidden=\"true\">\u003c/i>重试同步\u003c/div>\u003c/div>\n          \u003cdiv class=\"collection-filters\" role=\"group\" aria-label=\"收集状态\">\u003cdiv role=\"button\" tabindex=\"-1\" data-collection-filter=\"all\" aria-pressed=\"true\" aria-disabled=\"true\">全部\u003c/div>\u003cdiv role=\"button\" tabindex=\"-1\" data-collection-filter=\"uncollected\" aria-pressed=\"false\" aria-disabled=\"true\">未收集\u003c/div>\u003cdiv role=\"button\" tabindex=\"-1\" data-collection-filter=\"collected\" aria-pressed=\"false\" aria-disabled=\"true\">已收集\u003c/div>\u003c/div>\n        \u003c/div>\n        \u003cdiv class=\"preset-grid\" id=\"filter-presets\" aria-label=\"快捷筛选\">\u003c/div>\n        \u003cdiv class=\"layer-toolbar\">\n          \u003cdiv data-nrc-tag=button id=\"select-all\" data-nrc-type=\"button\">全部显示\u003c/div>\n          \u003cdiv data-nrc-tag=button id=\"select-none\" data-nrc-type=\"button\">清空选择\u003c/div>\n        \u003c/div>\n        \u003cdiv data-nrc-tag=label class=\"filter-search\">\n          \u003ci class=\"ui-icon fa-solid fa-magnifying-glass\" aria-hidden=\"true\">\u003c/i>\n          \u003cinput id=\"category-search\" type=\"search\" placeholder=\"筛选类型，如「魔法石」\" aria-label=\"筛选点位类型\" />\n        \u003c/div>\n        \u003cdiv class=\"layer-summary\">\n          \u003cspan id=\"selection-summary\">选择想显示的点位\u003c/span>\n        \u003c/div>\n        \u003cdiv class=\"class-filters\" id=\"class-filters\">\u003c/div>\n        \u003cp class=\"filter-empty\" id=\"filter-empty\" hidden>没有这种类型，试试「宝箱」或「精灵」。\u003c/p>\n        \u003c/div>\n        \u003cdiv class=\"panel-footer\">\u003cspan>筛选自动保存在本机\u003c/span>\u003cdiv data-nrc-tag=button id=\"quality-open\" data-nrc-type=\"button\">地图说明\u003c/div>\u003c/div>\n        \u003cdiv data-nrc-tag=button class=\"filter-done mobile-only\" id=\"filter-done\" data-nrc-type=\"button\">查看地图\u003c/div>\n      \u003c/div>\n\n      \u003cdiv data-nrc-tag=main class=\"map-shell\" id=\"map-shell\">\n        \u003ccanvas id=\"map-canvas\" tabindex=\"0\" aria-label=\"交互地图。方向键平移，加减号缩放，0 回到全图；可使用顶部搜索查找点位。\">\u003c/canvas>\n        \u003cdiv class=\"map-focus\" id=\"map-focus\" aria-hidden=\"true\" hidden>\u003c/div>\n        \u003cdiv class=\"map-context\">\u003cdiv class=\"location-readout\">\u003cspan id=\"large-region\">卡洛西亚大陆\u003c/span>\u003ci class=\"fa-solid fa-chevron-right\" aria-hidden=\"true\">\u003c/i>\u003cstrong id=\"current-region\">拖动地图，开始探索\u003c/strong>\u003c/div>\u003cspan class=\"map-filter-label\" id=\"active-filter-label\">探索\u003c/span>\u003c/div>\n        \u003cdiv class=\"map-search-filter\" id=\"map-search-filter\" hidden>\u003ci class=\"fa-solid fa-magnifying-glass\" aria-hidden=\"true\">\u003c/i>\u003cspan>\u003c/span>\u003cdiv data-nrc-tag=button data-nrc-type=\"button\" id=\"clear-map-search\" aria-label=\"退出搜索结果，恢复分类筛选\">\u003ci class=\"fa-solid fa-xmark\" aria-hidden=\"true\">\u003c/i>\u003c/div>\u003c/div>\n        \u003cdiv class=\"map-tooltip\" id=\"map-tooltip\" hidden>\u003c/div>\n        \u003cdiv data-nrc-tag=section id=\"point-picker\" class=\"point-picker\" role=\"dialog\" aria-label=\"选择重合点位\" hidden>\n          \u003cdiv class=\"point-picker-heading\">\u003cstrong>选择点位\u003c/strong>\u003cdiv data-nrc-tag=button data-nrc-type=\"button\" id=\"point-picker-close\" aria-label=\"关闭点位菜单\">\u003ci class=\"fa-solid fa-xmark\" aria-hidden=\"true\">\u003c/i>\u003c/div>\u003c/div>\n          \u003cdiv id=\"point-picker-list\" class=\"point-picker-list\">\u003c/div>\n        \u003c/div>\n        \u003cdiv data-nrc-tag=nav class=\"floor-switch\" id=\"floor-switch\" aria-label=\"探索楼层\" hidden>\n          \u003cdiv data-nrc-tag=button data-nrc-type=\"button\" data-floor=\"surface\" aria-pressed=\"true\">\u003ci class=\"fa-solid fa-map\" aria-hidden=\"true\">\u003c/i> 大地图\u003c/div>\n          \u003cdiv data-nrc-tag=button data-nrc-type=\"button\" data-floor=\"floor-1\" aria-pressed=\"false\">地底一层\u003c/div>\n          \u003cdiv data-nrc-tag=button data-nrc-type=\"button\" data-floor=\"floor-2\" aria-pressed=\"false\">地底二层\u003c/div>\n        \u003c/div>\n        \u003cdiv class=\"map-controls\" aria-label=\"地图控制\">\n          \u003cdiv data-nrc-tag=button id=\"map-quality-toggle\" class=\"map-quality-toggle\" data-nrc-type=\"button\" aria-label=\"切换到高清原图\" aria-pressed=\"false\" disabled>\u003cspan>标准\u003c/span>\u003c/div>\n          \u003cdiv data-nrc-tag=button id=\"zoom-in\" data-nrc-type=\"button\" title=\"放大\" aria-label=\"放大\">\u003ci class=\"ui-icon fa-solid fa-plus\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n          \u003cspan id=\"zoom-label\">100%\u003c/span>\n          \u003cdiv data-nrc-tag=button id=\"zoom-out\" data-nrc-type=\"button\" title=\"缩小\" aria-label=\"缩小\">\u003ci class=\"ui-icon fa-solid fa-minus\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n          \u003cdiv data-nrc-tag=button id=\"reset-view\" data-nrc-type=\"button\" title=\"回到全图\" aria-label=\"回到全图\">\u003ci class=\"ui-icon fa-solid fa-expand\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n        \u003c/div>\n        \u003cdiv class=\"map-empty\" id=\"map-empty\" hidden>\u003cstrong id=\"empty-title\">当前视野没有点位\u003c/strong>\u003cp id=\"empty-description\">拖动地图或更换筛选试试。\u003c/p>\u003cdiv data-nrc-tag=button id=\"empty-reset\" data-nrc-type=\"button\">显示探索点位\u003c/div>\u003cdiv data-nrc-tag=button id=\"empty-fit\" data-nrc-type=\"button\">回到全图\u003c/div>\u003c/div>\n        \u003cdiv class=\"map-status\">\n          \u003cspan>\u003cb id=\"visible-count\">0\u003c/b> 个点位在视野内\u003c/span>\n          \u003cspan class=\"map-gesture-hint\">拖动探索 · 滚轮缩放\u003c/span>\n          \u003cspan id=\"coordinate-label\" hidden>X — · Y —\u003c/span>\n        \u003c/div>\n      \u003c/div>\n\n      \u003cdiv data-nrc-tag=aside class=\"detail-panel\" id=\"detail-panel\" aria-label=\"点位详情\" aria-hidden=\"true\" inert>\n        \u003cdiv data-nrc-tag=button class=\"detail-close\" id=\"detail-close\" data-nrc-type=\"button\" aria-label=\"关闭详情\">\u003ci class=\"ui-icon fa-solid fa-xmark\" aria-hidden=\"true\">\u003c/i>\u003c/div>\n        \u003cdiv id=\"detail-content\">\u003c/div>\n      \u003c/div>\n\n      \u003cdiv class=\"scrim\" id=\"scrim\" hidden>\u003c/div>\n    \u003c/div>";
    window.NrcDivUI.scan(root);
    // 纯交互规则：不修改地图数据，便于在无浏览器环境验证。
const NON_CHALLENGE_GAMEPLAY = new Set(["火盆", "天气石像", "力气测试仪", "女神祭坛", "扭蛋机", "赛季玩法"]);

const PRESETS = [
  { id:"explore", label:"探索", hint:"传送与庇护所", genre:"魔力之源", match:c => c.classId === 2 },
  { id:"pets", label:"精灵", hint:"区域栖息地", genre:"精灵栖息地", match:c => c.classId === 7 },
  { id:"chests", label:"宝箱", hint:"收集与奖励", genre:"高级宝箱", match:c => c.genre.includes("宝箱") || c.genre.endsWith('闪光点') },
  { id:"gather", label:"采集", hint:"花草与矿石", genre:"向阳花", match:c => c.classId === 8 },
  { id:"challenge", label:"挑战", hint:"首领与对战", genre:"传说挑战", match:c => [3,9].includes(c.classId) || (c.classId === 4 && !NON_CHALLENGE_GAMEPLAY.has(c.genre)) },
  { id:"stars", label:"眠枭之星", hint:"星星与石像", genre:"金色眠枭之星", match:c => c.genre.includes("眠枭之星") },
];

function presetCategories(categories, presetId) {
  const preset = PRESETS.find(item => item.id === presetId);
  return new Set(categories.filter(c => preset?.match(c)).map(c => c.id));
}

function preferenceKey(mapId) { return `nrc-map:filters:v1:${mapId}`; }

function markerStyle(point, selected = false) {
  const portrait = ["portrait", "npc"].includes(point.iconKind) || /\/(?:map-heads|NPC)\/|\/PEO_/.test(point.icon || "");
  const compact = /智慧树苗|商店|商人|博得|安妮|皮卡/.test(point.genre || "");
  return { portrait, size:(portrait && point.classId === 3 ? 42 : portrait && point.classId === 9 ? 38 : point.iconKind === "npc" ? 34 : compact ? 26 : portrait ? 30 : 32) + (selected ? 4 : 0) };
}

// Deduplicate the selected marker's extra drawing pass, and include markers
// hidden behind another hit. Only selectable (rendered/filtered) hits enter.
function pointsAtHit(hits, position) {
  const unique = new Map();
  for (const hit of hits) {
    if (Math.hypot(position.x - hit.x, position.y - hit.y) > hit.radius) continue;
    unique.set(hit.point.id, hit.point);
  }
  return [...unique.values()];
}

const FLOOR_LABELS = { surface:"大地图", "floor-1":"地底一层", "floor-2":"地底二层", "floor-3":"地底三层" };

function availableFloors(layers) {
  const named = new Set(layers.filter(l => l.kind === "underground").map(patchFloor));
  if (named.has(null)) { named.add("floor-1"); named.add("floor-2"); }
  return Object.keys(FLOOR_LABELS).filter(id => id === "surface" || named.has(id));
}

function patchFloor(layer) {
  if (!layer || layer.kind === "surface" || layer.id === "surface") return "surface";
  if (/第?三层/.test(layer.name)) return "floor-3";
  if (/第?二层/.test(layer.name)) return "floor-2";
  if (/第?一层/.test(layer.name)) return "floor-1";
  return null;
}

function patchOnFloor(layer, floor) {
  return layer?.kind === "underground" && (patchFloor(layer) === floor || (!patchFloor(layer) && ["floor-1", "floor-2"].includes(floor)));
}

function pointOnFloor(point, floor, layers) {
  if (floor === "surface") return true;
  return (point.mapLayerIds || [point.mapLayerId]).some(id => {
    const layer = layers.get(id);
    return patchOnFloor(layer, floor);
  });
}

function filterHabitatPets(pets, query) {
  const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  return pets.filter(pet => {
    const text = `${pet.name} ${pet.form || ""} ${(pet.types || []).map(t => t.name).join(" ")}`.toLowerCase();
    return terms.every(term => text.includes(term));
  });
}

// Region words in a global search must not hide the pet that matched its name.
function habitatQuery(pets, query) {
  return query.trim().toLowerCase().split(/\s+/).filter(term => term && pets.some(pet =>
    `${pet.name} ${pet.form || ""}`.toLowerCase().includes(term))).join(" ");
}

function floorForPoint(point, current, layers) {
  const ids = point.mapLayerIds || [point.mapLayerId];
  if (current !== "surface" && pointOnFloor(point, current, layers)) return current;
  const layer = ids.map(id => layers.get(id)).find(layer => layer?.kind === "underground");
  return layer ? patchFloor(layer) || "floor-1" : "surface";
}

function restorePreferences(raw, categories) {
  try {
    const saved = JSON.parse(raw);
    if (saved?.version !== 1 || !Array.isArray(saved.categories)) return null;
    const known = new Set(categories.map(c => c.id));
    const enabled = saved.categories.filter(id => known.has(id));
    if (saved.categories.length && !enabled.length) return null;
    return { categories:new Set(enabled) };
  } catch { return null; }
}

function pinchTransform(start, a, b, viewport, minScale, maxScale) {
  const midpoint = { x:(a.x + b.x) / 2, y:(a.y + b.y) / 2 };
  const distance = Math.hypot(a.x - b.x, a.y - b.y);
  const scale = Math.max(minScale, Math.min(maxScale, start.scale * distance / Math.max(start.distance, 1)));
  return {
    scale,
    x:start.anchor.x - (midpoint.x - viewport.width / 2) / scale,
    y:start.anchor.y - (midpoint.y - viewport.height / 2) / scale,
  };
}

// Account storage follows the GrassTrial tracker: Data Wiki, revision baselines,
// server timestamps, operation merging and rollback. No local progress fallback.
const COLLECTION_GENRES = new Set([
  '音乐收集', '蓝色眠枭之星', '金色眠枭之星', '紫色眠枭之星',
  '初级宝箱', '高级宝箱', '系别宝箱', '精灵问答宝箱', '初级闪光点', '中级闪光点', '高级闪光点', '力气测试仪', '小游戏',
  '蓝色智慧树苗', '金色智慧树苗', '紫色智慧树苗',
  '不咕钟零件', '扭蛋机',
]);
const COLLECTION_PATH = 'nrc/world-map/collected-v1.json';
const COLLECTION_ID = /^p-[0-9a-f]{16}$/;
const COLLECTION_MAX_BYTES = 2 * 1024 * 1024;
const COLLECTION_MAX_IDS = 50000;
const collectionTimestamp = value => typeof value === 'string' && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$/.test(value) && Number.isFinite(Date.parse(value));
const collectionRevision = value => Number.isSafeInteger(Number(value)) && Number(value) > 0;
const collectionError = (code, message) => Object.assign(new Error(message || code), {code});
const collectionAuthError = error => ['assertnameduserfailed','assertuserfailed','assertionfailed','notloggedin','mustbeloggedin'].includes(error?.code);
const collectionRetryable = error => ['editconflict','articleexists','badtoken','notoken','missingtitle','pagedeleted','readonly','maxlag','network'].includes(error?.code);

function isCollectible(point) { return COLLECTION_GENRES.has(point?.genre); }
function collectionUserId(cookie = '') {
  let value = cookie.match(/(?:^|;\s*)DedeUserID=([^;]*)/)?.[1] || '';
  try { value = decodeURIComponent(value); } catch { return ''; }
  return /^\d{1,20}$/.test(value) ? value : '';
}
function collectionMatches(point, filter, store) {
  if (filter === 'all' || !store.available) return true;
  return isCollectible(point) && store.has(point.id) === (filter === 'collected');
}
function parseCollection(text) {
  if (typeof text !== 'string' || new TextEncoder().encode(text).length > COLLECTION_MAX_BYTES) throw collectionError('invalid-data');
  let envelope;
  try { envelope = JSON.parse(text); } catch { throw collectionError('invalid-data'); }
  const ids = envelope?.data?.collected;
  if (envelope?.head?.zipped !== false || !collectionTimestamp(envelope.head.version) || envelope?.data?.schema !== 1 || !Array.isArray(ids) || ids.length > COLLECTION_MAX_IDS) throw collectionError('invalid-data');
  const result = new Set();
  for (const id of ids) {
    if (typeof id !== 'string' || !COLLECTION_ID.test(id) || result.has(id)) throw collectionError('invalid-data');
    result.add(id);
  }
  return result;
}
function serializeCollection(collected, timestamp) {
  if (!collectionTimestamp(timestamp)) throw collectionError('invalid-response');
  const text = JSON.stringify({head:{version:timestamp,zipped:false},data:{schema:1,collected:[...collected].sort()}});
  parseCollection(text);
  return text;
}
function applyCollection(saved, operations) {
  const result = new Set(saved);
  for (const [id, value] of operations) { if (value) result.add(id); else result.delete(id); }
  return result;
}

async function collectionRequest(parameters, method = 'GET') {
  const body = new URLSearchParams({...parameters,format:'json',formatversion:2,assert:'user'});
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(),20000);
  try {
    const response = await fetch('/data/api.php' + (method === 'GET' ? '?' + body : ''), {
      method,credentials:'same-origin',cache:'no-store',signal:abort.signal,
      ...(method === 'POST' ? {body} : {}),
    });
    if (!response.ok) throw collectionError('network');
    const result = await response.json();
    if (result?.error) throw collectionError(result.error.code || 'api-error');
    if (!result || typeof result !== 'object') throw collectionError('invalid-response');
    return result;
  } catch (error) {
    throw error.code ? error : collectionError('network');
  } finally { clearTimeout(timer); }
}

class CollectionStore {
  constructor({uid = '', request = collectionRequest, onChange = () => {}, debounce = 300} = {}) {
    this.uid = /^\d{1,20}$/.test(uid) ? uid : '';
    this.title = this.uid ? `用户:${this.uid}/${COLLECTION_PATH}` : '';
    this.request = request; this.onChange = onChange; this.debounce = debounce;
    this.saved = new Set(); this.pending = new Map(); this.inFlight = null;
    this.remote = null; this.loaded = false; this.loading = false; this.saving = false;
    this.authFailed = false; this.blocked = false; this.error = ''; this.lastSync = 0;
    this.timer = null; this.savingPromise = null; this.refreshPromise = null;
    this.refreshAfterSave = false;
  }
  get available() { return !!this.uid && this.loaded && !this.authFailed && !this.blocked; }
  get dirty() { return this.saving || this.pending.size > 0; }
  has(id) {
    if (this.pending.has(id)) return this.pending.get(id);
    if (this.inFlight?.has(id)) return this.inFlight.get(id);
    return this.saved.has(id);
  }
  changed() { this.onChange(this); }
  async fetchRemote() {
    if (!this.uid) throw collectionError('notloggedin');
    const response = await this.request({action:'query',prop:'revisions',titles:this.title,rvprop:'ids|timestamp|content',rvslots:'main',rvlimit:1,meta:'tokens',type:'csrf',curtimestamp:1,assertuser:this.uid});
    const pages = response?.query?.pages, token = response?.query?.tokens?.csrftoken;
    if (!Array.isArray(pages) || pages.length !== 1 || typeof token !== 'string' || !token || token === '+\\' || !collectionTimestamp(response.curtimestamp)) throw collectionError('invalid-response');
    const page = pages[0];
    if (!page || page.invalid) throw collectionError('invalid-response');
    const common = {token,starttimestamp:response.curtimestamp};
    if (page.missing) return {...common,exists:false,revid:0,timestamp:'',collected:new Set()};
    const revision = page.revisions?.[0];
    if (page.revisions?.length !== 1 || !collectionRevision(revision?.revid) || !collectionTimestamp(revision.timestamp)) throw collectionError('invalid-response');
    const main = revision.slots?.main;
    const content = main?.content ?? main?.['*'] ?? revision.content ?? revision['*'];
    return {...common,exists:true,revid:Number(revision.revid),timestamp:revision.timestamp,collected:parseCollection(content)};
  }
  accept(remote) { this.remote = remote; this.saved = new Set(remote.collected); this.loaded = true; this.lastSync = Date.now(); }
  async writeRemote(target) {
    const remote = this.remote;
    if (!remote?.token) throw collectionError('badtoken');
    const parameters = {action:'edit',title:this.title,text:serializeCollection(target,remote.starttimestamp),token:remote.token,summary:'更新世界地图收集记录',watchlist:'nochange',curtimestamp:1,assertuser:this.uid,starttimestamp:remote.starttimestamp};
    if (remote.exists) {
      if (!collectionRevision(remote.revid) || !collectionTimestamp(remote.timestamp)) throw collectionError('editconflict');
      Object.assign(parameters,{baserevid:remote.revid,basetimestamp:remote.timestamp,nocreate:1});
    } else parameters.createonly = 1;
    const response = await this.request(parameters,'POST');
    const edit = response?.edit;
    if (edit?.result !== 'Success' || !collectionTimestamp(response.curtimestamp)) throw collectionError('invalid-response');
    if (edit.nochange === true) {
      if (!remote.exists || !collectionRevision(remote.revid) || !collectionTimestamp(remote.timestamp)) throw collectionError('invalid-response');
      return {...remote,collected:target,starttimestamp:response.curtimestamp};
    }
    if (!collectionRevision(edit.newrevid)) throw collectionError('invalid-response');
    return {...remote,exists:true,revid:Number(edit.newrevid),timestamp:collectionTimestamp(edit.newtimestamp) ? edit.newtimestamp : '',starttimestamp:response.curtimestamp,collected:target};
  }
  refresh(force = false) {
    if (!this.uid || this.authFailed || (!force && Date.now()-this.lastSync < 15000)) return Promise.resolve();
    if (this.saving) return this.savingPromise.then(() => this.refresh(force));
    if (this.loading) return this.refreshPromise;
    this.loading = true; this.error = ''; this.changed();
    this.refreshPromise = this.fetchRemote().then(remote => {
      this.accept(remote); this.blocked = false; this.error = '';
    }).catch(error => {
      this.authFailed = collectionAuthError(error);
      if (error.code === 'invalid-data') this.blocked = true;
      if (this.authFailed || this.blocked) this.pending.clear();
      this.error = this.authFailed ? '登录已失效，请重新登录' : this.blocked ? '收集记录暂时无法读取，未改动已保存的记录' : '读取失败，请重试';
    }).finally(() => {
      this.loading = false; this.changed();
      if (this.available && this.pending.size) this.schedule();
    });
    return this.refreshPromise;
  }
  toggle(id) {
    if (!this.available || !COLLECTION_ID.test(id)) return false;
    this.pending.set(id,!this.has(id)); this.error = ''; this.changed(); this.schedule();
    return true;
  }
  schedule() { clearTimeout(this.timer); this.timer = setTimeout(() => this.flush(),this.debounce); }
  flush() {
    clearTimeout(this.timer);
    if (this.saving) return this.savingPromise;
    if (this.loading) return this.refreshPromise.then(() => this.flush());
    if (!this.available || !this.pending.size) return Promise.resolve();
    const operations = this.pending;
    this.pending = new Map(); this.inFlight = operations; this.saving = true; this.changed();
    this.savingPromise = this.saveOperations(operations).finally(() => {
      clearTimeout(this.timer);
      this.inFlight = null; this.saving = false; this.changed();
      if (this.refreshAfterSave) { this.refreshAfterSave = false; this.refresh(true); }
      else if (this.available && this.pending.size) this.schedule();
    });
    return this.savingPromise;
  }
  async saveOperations(operations) {
    try {
      for (let attempt = 0; attempt < 3; attempt++) {
        const target = applyCollection(this.saved,operations);
        try {
          const remote = await this.writeRemote(target);
          this.accept(remote); this.error = '';
          // A new revision without its timestamp cannot be the next edit's baseline.
          if (!remote.timestamp) this.refreshAfterSave = true;
          return;
        } catch (error) {
          if (attempt === 2 || !collectionRetryable(error)) throw error;
          this.accept(await this.fetchRemote());
        }
      }
    } catch (error) {
      this.authFailed = collectionAuthError(error);
      if (error.code === 'invalid-data') this.blocked = true;
      if (this.authFailed || this.blocked) this.pending.clear();
      this.error = this.authFailed ? '登录已失效，本次修改未保存' : '保存失败，本次修改已撤销，请重试';
      this.lastSync = 0;
    }
  }
}

// Point identities and rocom pageids are resolved at build time. No title lookup
// or credential relay is performed when a visitor opens a marker.
const POINT_COMMENT_API = 'https://wiki.biligame.com/rocom/api.php';
const pointCommentTitle = id => 'Point:' + id[0].toUpperCase() + id.slice(1);
const pointCommentUrl = id => 'https://wiki.biligame.com/rocom/' + encodeURIComponent(pointCommentTitle(id));

function createPointCommentApi({fetcher = (...args) => fetch(...args), origin = location.origin,
  cookie = () => document.cookie, login = () => window.UserStatus?.quickLogin?.(() => location.reload())} = {}) {
  const sameOrigin = origin === new URL(POINT_COMMENT_API).origin;
  let user = null, token = '', authTime = 0, authRequest = null;
  const uid = () => cookie().match(/(?:^|;\s*)DedeUserID=(\d+)/)?.[1] || '';
  async function request(method, values) {
    const params = new URLSearchParams(Object.entries({format:'json', formatversion:2, ...values})
      .filter(([,v]) => v !== false && v !== null && v !== undefined));
    if (!sameOrigin) params.set('origin','*');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 25000);
    try {
      const response = await fetcher(POINT_COMMENT_API + (method === 'GET' ? '?' + params : ''), {
        method, credentials:sameOrigin ? 'same-origin' : 'omit', signal:controller.signal,
        ...(method === 'POST' ? {body:params} : {})
      });
      if (!response.ok) throw new Error('评论服务暂时无法访问，请稍后重试。');
      const result = await response.json();
      if (result.error) throw result;
      return result;
    } finally { clearTimeout(timeout); }
  }
  async function refreshAuth(force = false) {
    if (!sameOrigin) return;
    if (!force && user && Date.now() - authTime < 30000 && user.name === uid()) return;
    if (authRequest) return authRequest;
    authRequest = request('GET', {action:'query', meta:'userinfo|tokens', type:'csrf'}).then(result => {
      user = result.query?.userinfo || null;
      token = result.query?.tokens?.csrftoken || '';
      authTime = Date.now();
    }).finally(() => { authRequest = null; });
    return authRequest;
  }
  return {
    get userId() { return user?.name || ''; },
    get available() { return sameOrigin && !!user && !user.anon && user.id > 0 && user.name === uid() && token !== '+\\' && !!token; },
    ready:() => refreshAuth().catch(() => {}),
    login,
    get:values => request('GET', values),
    async postWithToken(kind, values) {
      if (!sameOrigin) throw new Error('请在 Wiki 登录后参与评论。');
      await refreshAuth(true);
      if (!user || user.anon || user.name !== uid() || !token || token === '+\\') throw new Error('登录已失效，请重新登录；内容已保留。');
      const params = {...values, assert:'user', assertuser:user.name, token};
      try { return await request('POST', params); }
      catch (error) {
        if (error?.error?.code !== 'badtoken') throw error;
        await refreshAuth(true);
        if (!user || user.anon || user.name !== params.assertuser) throw new Error('登录已失效，内容已保留。');
        return request('POST', {...params, token});
      }
    }
  };
}

function createPointComments({api = createPointCommentApi(), mount = (host, options) => window.NrcPointFlowThread.mount(host, options)} = {}) {
  let active = null, generation = 0;
  const drafts = new Map(), pending = new Map(), outcomes = new Map();
  return {
    close() { generation++; active?.destroy(); active = null; },
    async show(host, point) {
      this.close();
      const current = generation;
      const status = document.createElement('div');
      status.className = 'map-comment-status';
      status.textContent = '正在加载评论…';
      const reference = document.createElement('div');
      reference.className = 'map-comment-reference';
      const link = document.createElement('a');
      link.href = pointCommentUrl(point.id); link.target = '_blank'; link.rel = 'noopener';
      link.textContent = point.id; link.title = '打开此点位的独立评论页';
      reference.append(document.createTextNode('点位编号 '), link);
      const content = document.createElement('div'); content.append(status);
      host.replaceChildren(reference, content);
      if (!Number.isSafeInteger(point.commentPageId) || point.commentPageId <= 0) {
        status.textContent = '此点位的评论暂未开放。'; return;
      }
      if (pending.has(point.id)) status.textContent = '此点位的评论正在提交，请稍候…';
      await Promise.all([api.ready(), pending.get(point.id)?.promise]);
      if (generation !== current || !host.isConnected) return;
      const pointApi = Object.create(api);
      pointApi.login = () => {
        if (location.origin === new URL(POINT_COMMENT_API).origin) api.login();
        else window.open(pointCommentUrl(point.id), '_blank', 'noopener');
      };
      try {
        active = mount(content, {articleId:point.commentPageId, api:pointApi,
          draft:drafts.get(point.id), lastStatus:outcomes.get(point.id),
          saveDraft:draft => draft?.text ? drafts.set(point.id,draft) : drafts.delete(point.id),
          onSubmitStart() {
            let resolve;
            const promise = new Promise(done => {resolve = done;});
            pending.set(point.id, {promise, resolve});
          },
          onSubmitEnd(outcome) {
            outcomes.set(point.id, outcome);
            const request = pending.get(point.id);
            pending.delete(point.id); request?.resolve();
          }});
      } catch (_) {
        status.textContent = '评论暂时无法加载，请重新打开此点位。';
        content.replaceChildren(status);
      }
    }
  };
}

const $ = (selector, scope = root) => scope.querySelector(selector);
const $$ = (selector, scope = root) => [...scope.querySelectorAll(selector)];
const pointComments = createPointComments();

const MAP_PIXELS = 4096;
const SURFACE_MAP_RECT = Object.freeze({ x: 0, y: 0, width: MAP_PIXELS, height: MAP_PIXELS });
const MAP_CATALOG = {
  mainland: { label: "卡洛西亚大陆", dataRoot: "/map-data/mainland" },
  academy: { label: "魔法学院", dataRoot: "/map-data/academy" },
};
const initialParams = new URLSearchParams(window.location.search);
const requestedMapId = initialParams.get("map");
const requestedSpatialLayerId = initialParams.get("layer") || "surface";
const activeMapId = Object.hasOwn(MAP_CATALOG, requestedMapId) ? requestedMapId : "mainland";
const activeMap = MAP_CATALOG[activeMapId];
const CLASS_COLORS = {
  2: "#98d27a",
  3: "#e68167",
  4: "#d4af65",
  5: "#76b7d2",
  6: "#d7c4e8",
  7: "#d4bd93",
  8: "#79b9a4",
  9: "#d78a88",
};

const dom = {
  canvas: $("#map-canvas"),
  focus: $("#map-focus"),
  mapShell: $("#map-shell"),
  loading: $("#loading-card"),
  loadingTitle: $("#loading-title"),
  loadingDetail: $("#loading-detail"),
  mapSelect: $("#map-select"),
  largeRegion: $("#large-region"),
  currentRegion: $("#current-region"),
  coordinate: $("#coordinate-label"),
  visibleCount: $("#visible-count"),
  zoomLabel: $("#zoom-label"),
  tooltip: $("#map-tooltip"),
  filters: $("#class-filters"),
  categorySearch: $("#category-search"),
  globalSearch: $("#global-search"),
  searchResults: $("#search-results"),
  details: $("#detail-panel"),
  detailContent: $("#detail-content"),
  layerPanel: $("#layer-panel"),
  scrim: $("#scrim"),
};

const state = {
  core: null,
  points: [],
  layerPoints: [],
  pointById: new Map(),
  allCategories: [],
  categoryById: new Map(),
  enabledCategories: new Set(),
  spatialLayers: [],
  spatialLayerById: new Map(),
  activeSpatialLayerId: "surface",
  focusedPatchId: null,
  pointers: new Map(),
  pinch: null,
  gestureMoved: false,
  searchIndex: -1,
  cameraAnimation: null,
  mapQuality: "standard",
  qualityChanging: false,
  qualityEpoch: 0,
  tiles: [],
  maskTiles: [],
  undergroundTiles: [],
  tileErrors: 0,
  surfaceTilePromise: null,
  layerImages: new Map(),
  layerImagePromises: new Map(),
  iconCache: new Map(),
  markerCache: new Map(),
  grid: null,
  bounds: null,
  camera: { x: MAP_PIXELS / 2, y: MAP_PIXELS / 2, scale: 0.2, fitScale: 0.2 },
  viewport: { width: 1, height: 1, dpr: 1 },
  hits: [],
  hoveredHit: null,
  selectedPoint: null,
  dragging: false,
  dragStart: null,
  dragDistance: 0,
  framePending: false,
  layerRequest: 0,
  searchMatches: [],
  mapSearch: null,
  habitatQuery: "",
  collectionFilter: "all",
};
const collection = new CollectionStore({uid:collectionUserId(document.cookie),onChange:onCollectionChange});

function escapeHtml(value) {
  if (typeof value === "string" && value.startsWith("/map-media/")) value = assetUrl(value);
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function textHtml(value) {
  return escapeHtml(value).replaceAll("\n", "<br />");
}

function categoryKey(point) {
  return `${point.classId}:${point.genre}`;
}

function matchesCollection(point) { return collectionMatches(point,state.collectionFilter,collection); }
function collectedPoint(point) { return collection.available && isCollectible(point) && collection.has(point.id); }
function collectionButtonText(point) {
  if (!collection.uid || collection.authFailed) return '登录后标记';
  if (!collection.available) return collection.loading ? '正在读取收集记录…' : '重试读取记录';
  return collectedPoint(point) ? '已收集 · 点击取消' : '标记为已收集';
}
function renderCollectionControl(point) {
  if (!isCollectible(point)) return '';
  return `<div class="point-collection"><div class="collection-toggle" role="button" tabindex="0" data-collection-toggle="${escapeHtml(point.id)}" aria-pressed="${collectedPoint(point)}"><i class="fa-solid fa-${collectedPoint(point) ? 'circle-check' : 'circle-plus'}" aria-hidden="true"></i><div>${collectionButtonText(point)}</div></div><div class="collection-detail-status" role="status"></div></div>`;
}
function loginCollection() {
  if (window.UserStatus?.quickLogin) {
    window.UserStatus.quickLogin(() => { const url = new URL(location.href); url.searchParams.set('biliLogin','1'); location.assign(url); });
  } else window.open('https://wiki.biligame.com/nrc/Special:UserLogin?returnto=' + encodeURIComponent('地图'),'_blank','noopener');
}
function collectionStatus() {
  if (collection.error) return collection.error;
  if (!collection.uid || collection.authFailed) return '登录后记录收集进度';
  if (collection.loading && !collection.loaded) return '正在读取收集记录…';
  if (collection.dirty) return '正在保存…';
  return collection.available ? '已同步' : '收集记录尚未加载';
}
function updateCollectionUI() {
  const panel = $('#collection-panel');
  if (!panel || !state.core) return;
  const counts = new Map();
  let total = 0, done = 0;
  for (const point of state.layerPoints) {
    if (!isCollectible(point)) continue;
    const key = categoryKey(point), count = counts.get(key) || {total:0,done:0};
    count.total++; if (collection.has(point.id)) count.done++;
    counts.set(key,count);
    if (state.mapSearch ? state.mapSearch.ids.has(point.id) : state.enabledCategories.has(key)) { total++; if (collection.has(point.id)) done++; }
  }
  $('#collection-progress').textContent = collection.available ? `已收集 ${done} / ${total}` : '收集进度';
  $('#collection-status').textContent = collectionStatus();
  panel.classList.toggle('has-error',Boolean(collection.error));
  $('#collection-login').hidden = !!collection.uid && !collection.authFailed;
  $('#collection-retry').hidden = !collection.uid || collection.authFailed || !collection.error;
  $$('[data-collection-filter]').forEach(button => {
    button.setAttribute('aria-pressed',String(button.dataset.collectionFilter === state.collectionFilter));
    button.setAttribute('aria-disabled',String(!collection.available));
    button.tabIndex = collection.available ? 0 : -1;
  });
  $$('[data-collection-category]').forEach(label => {
    const count = counts.get(label.dataset.collectionCategory) || {total:0,done:0};
    label.hidden = !collection.available;
    label.textContent = `未 ${count.total-count.done} · 已 ${count.done}`;
  });
  $$('[data-collection-toggle]').forEach(button => {
    const point = state.pointById.get(button.dataset.collectionToggle);
    if (!point) return;
    const marked = collectedPoint(point);
    button.setAttribute('aria-pressed',String(marked));
    button.setAttribute('aria-disabled',String(collection.loading && !collection.loaded));
    button.innerHTML = `<i class="fa-solid fa-${marked ? 'circle-check' : 'circle-plus'}" aria-hidden="true"></i><div>${collectionButtonText(point)}</div>`;
  });
  $$('.collection-detail-status').forEach(label => { label.textContent = collection.error || (collection.available && collection.dirty ? '正在保存…' : ''); });
}
function onCollectionChange() {
  if (!state.core) return;
  if (!collection.available) state.collectionFilter = 'all';
  updateSelectionSummary();
  if (!dom.searchResults.hidden) updateSearchResults();
  closePointPicker(); hideTooltip(); scheduleRender();
}
function setCollectionFilter(value) {
  if (!collection.available || !['all','uncollected','collected'].includes(value)) return;
  state.collectionFilter = value;
  // Switching to collection results should work from the default travel-only preset.
  if (value !== 'all' && !state.categories.some(c => isCollectible(c) && state.enabledCategories.has(c.id))) selectCollectibleCategories();
  updateSelectionSummary();
  if (!dom.searchResults.hidden) updateSearchResults();
  closePointPicker(); hideTooltip(); scheduleRender();
}
function selectCollectibleCategories() {
  state.mapSearch = null;
  state.enabledCategories = new Set(state.categories.filter(isCollectible).map(c => c.id));
  enablePointLayer();
  $$('.category-check',dom.filters).forEach(input => { input.checked = state.enabledCategories.has(input.dataset.category); });
  updateClassCheckboxes(); savePreferences(); scheduleRender();
}

function inMapBounds(point) {
  const [minX, minY, maxX, maxY] = state.bounds;
  return point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY;
}

function projectWorld(x, y) {
  const [minX, minY] = state.bounds;
  const side = state.core.meta.sideLength;
  return {
    x: ((x - minX) / side) * MAP_PIXELS,
    y: ((y - minY) / side) * MAP_PIXELS,
  };
}

function unprojectMap(x, y) {
  const [minX, minY] = state.bounds;
  const side = state.core.meta.sideLength;
  return {
    x: minX + (x / MAP_PIXELS) * side,
    y: minY + (y / MAP_PIXELS) * side,
  };
}

function activeSpatialLayer() {
  return { id:state.activeSpatialLayerId, name:FLOOR_LABELS[state.activeSpatialLayerId], groupName:state.core.meta.sceneName, bounds:state.bounds };
}

function activeLayerMapRect(layer = activeSpatialLayer()) {
  if (!layer || layer.id === "surface") return SURFACE_MAP_RECT;
  const topLeft = projectWorld(layer.bounds[0], layer.bounds[1]);
  const bottomRight = projectWorld(layer.bounds[2], layer.bounds[3]);
  return {
    x: topLeft.x,
    y: topLeft.y,
    width: bottomRight.x - topLeft.x,
    height: bottomRight.y - topLeft.y,
  };
}

function pointInActiveSpatialLayer(point) {
  return pointOnFloor(point, state.activeSpatialLayerId, state.spatialLayerById);
}

function mapToScreen(x, y) {
  const { width, height } = state.viewport;
  const { camera } = state;
  return {
    x: width / 2 + (x - camera.x) * camera.scale,
    y: height / 2 + (y - camera.y) * camera.scale,
  };
}

function screenToMap(x, y) {
  const { width, height } = state.viewport;
  const { camera } = state;
  return {
    x: camera.x + (x - width / 2) / camera.scale,
    y: camera.y + (y - height / 2) / camera.scale,
  };
}

class SpatialGrid {
  constructor(points, cellSize = 128) {
    this.cellSize = cellSize;
    this.cells = new Map();
    for (const point of points) {
      const key = this.key(point.mx, point.my);
      const cell = this.cells.get(key) || [];
      cell.push(point);
      this.cells.set(key, cell);
    }
  }

  key(x, y) {
    return `${Math.floor(x / this.cellSize)},${Math.floor(y / this.cellSize)}`;
  }

  query(minX, minY, maxX, maxY) {
    const result = [];
    const x0 = Math.floor(minX / this.cellSize);
    const y0 = Math.floor(minY / this.cellSize);
    const x1 = Math.floor(maxX / this.cellSize);
    const y1 = Math.floor(maxY / this.cellSize);
    for (let y = y0; y <= y1; y += 1) {
      for (let x = x0; x <= x1; x += 1) {
        const cell = this.cells.get(`${x},${y}`);
        if (cell) result.push(...cell);
      }
    }
    return result;
  }
}

async function fetchJson(url) { return wikiData(url); }

function loadImage(url) {
  return new Promise((resolve) => {
    const image = new Image();
    image.decoding = "async";
    const timer = setTimeout(() => { image.onload = image.onerror = null; image.src = ""; resolve(null); }, 60000);
    image.onload = () => { clearTimeout(timer); resolve(image); };
    image.onerror = () => { clearTimeout(timer); resolve(null); };
    image.src = assetUrl(url);
  });
}

async function loadSpatialLayerImage(layerId) {
  const layer = state.spatialLayerById.get(layerId);
  const epoch = state.qualityEpoch;
  const url = state.mapQuality === "hd" && layer?.imageHD ? layer.imageHD : layer?.image;
  if (!url || state.layerImages.has(layerId)) return state.layerImages.get(layerId) || null;
  if (!state.layerImagePromises.has(layerId)) {
    state.layerImagePromises.set(layerId, loadImage(url).then((image) => {
      if (epoch !== state.qualityEpoch) return null;
      state.layerImages.set(layerId, image);
      state.layerImagePromises.delete(layerId);
      scheduleRender();
      return image;
    }));
  }
  return state.layerImagePromises.get(layerId);
}

function qualityLayout(key, quality = state.mapQuality) {
  return (quality === "hd" && state.core.meta.hdTileLayouts?.[key]) || state.core.meta[key];
}

function tileImages(key, quality = state.mapQuality) {
  const layout = qualityLayout(key, quality);
  return Promise.all(Array.from({ length: layout.columns * layout.rows }, (_, i) =>
    loadImage(layout.path.replace("{index}", String(i + 1).padStart(2, "0")))));
}

function updateQualityButton() {
  const button = $("#map-quality-toggle");
  const hd = state.mapQuality === "hd";
  button.disabled = state.qualityChanging;
  button.setAttribute("aria-pressed", String(hd));
  button.setAttribute("aria-label", state.qualityChanging ? "正在切换地图画质" : hd ? "当前高清，切换到标准画质" : "当前标准，切换到高清原图");
  button.title = button.getAttribute("aria-label");
  button.innerHTML = state.qualityChanging ? '<i class="fa-solid fa-spinner fa-spin" aria-hidden="true"></i>' : `<span>${hd ? "高清" : "标准"}</span>`;
}

async function setMapQuality(quality) {
  if (state.qualityChanging || quality === state.mapQuality || !state.core.meta.hdTileLayouts) return;
  state.qualityChanging = true;
  updateQualityButton();
  // Keep the current map visible and interactive until BOTH image sets are ready.
  const [tiles, masks] = await Promise.all([tileImages("openTileLayout", quality), tileImages("unexploredTileLayout", quality)]);
  const patches = activePatches();
  const [underground, patchImages] = await Promise.all([
    patches.length ? tileImages("undergroundTileLayout", quality) : [],
    Promise.all(patches.map(layer => loadImage(quality === "hd" && layer.imageHD ? layer.imageHD : layer.image))),
  ]);
  if ([...tiles, ...masks, ...underground, ...patchImages].some(image => !image)) {
    state.qualityChanging = false;
    updateQualityButton();
    showMapNotice("画质切换未完成，已保留当前地图。", () => setMapQuality(quality));
    return;
  }
  state.qualityEpoch++;
  state.mapQuality = quality;
  state.tiles = tiles;
  state.maskTiles = masks;
  state.undergroundTiles = underground;
  state.layerImages.clear();
  patches.forEach((layer, i) => state.layerImages.set(layer.id, patchImages[i]));
  state.layerImagePromises.clear();
  preparedTilePromises.clear();
  preparedTilePromises.set("unexplored", Promise.resolve(masks));
  if (underground.length) preparedTilePromises.set("underground", Promise.resolve(underground));
  state.surfaceTilePromise = Promise.resolve();
  try { localStorage.setItem("nrc-map:quality:v1", quality); } catch { /* private browsing */ }
  state.qualityChanging = false;
  updateQualityButton();
  scheduleRender();
  if (state.activeSpatialLayerId !== "surface") await Promise.all([loadActivePatches(), loadPreparedTiles("underground")]);
}

async function loadTiles() {
  state.tiles = await tileImages("openTileLayout");
  state.tileErrors = state.tiles.filter((tile) => !tile).length;
}

// All boundaries and darkening are baked into images; load optional layers only on demand.
const preparedTilePromises = new Map();
async function loadPreparedTiles(kind) {
  if (!preparedTilePromises.has(kind)) {
    const epoch = state.qualityEpoch;
    preparedTilePromises.set(kind, tileImages(kind === "unexplored" ? "unexploredTileLayout" : "undergroundTileLayout").then(images => {
      if (epoch !== state.qualityEpoch) return images;
      state[kind === "unexplored" ? "maskTiles" : "undergroundTiles"] = images;
      if (images.some(image => !image)) {
        preparedTilePromises.delete(kind);
        showMapNotice("部分地图图片未能加载，请重试。", () => loadPreparedTiles(kind));
      }
      scheduleRender();
      return images;
    }));
  }
  return preparedTilePromises.get(kind);
}

function ensureSurfaceTiles() {
  if (!state.surfaceTilePromise) state.surfaceTilePromise = loadTiles();
  return state.surfaceTilePromise;
}

async function initialize() {
  try {
    dom.mapSelect.value = activeMapId;
    dom.loadingTitle.textContent = "正在展开地图…";
    dom.loadingDetail.textContent = "寻找沿途的风景与精灵";
    const [core, pointData] = await Promise.all([
      fetchJson(`${activeMap.dataRoot}/map-core.json`),
      fetchJson(`${activeMap.dataRoot}/map-points.json`),
    ]);
    state.core = core;
    try { if (core.meta.hdTileLayouts && localStorage.getItem("nrc-map:quality:v1") === "hd") state.mapQuality = "hd"; } catch {}
    state.qualityChanging = true;
    updateQualityButton();
    state.bounds = core.meta.bounds;
    state.allCategories = core.categories;
    state.spatialLayers = core.spatialLayers || [{
      id: "surface", kind: "surface", name: core.meta.sceneName,
      groupName: core.meta.sceneName, bounds: core.meta.bounds, pointCount: pointData.points.length,
    }];
    state.spatialLayerById = new Map(state.spatialLayers.map((layer) => [layer.id, layer]));
    const requestedPatch = state.spatialLayerById.get(requestedSpatialLayerId);
    state.focusedPatchId = requestedPatch?.kind === "underground" ? requestedPatch.id : null;
    state.activeSpatialLayerId = availableFloors(state.spatialLayers).includes(requestedSpatialLayerId) ? requestedSpatialLayerId
      : requestedPatch?.kind === "underground" ? patchFloor(requestedPatch) || "floor-1" : "surface";
    state.categories = core.categories;
    state.categoryById = new Map(core.categories.map((category) => [category.id, category]));
    state.enabledCategories = presetCategories(core.categories, "explore");
    try {
      const saved = restorePreferences(localStorage.getItem(preferenceKey(activeMapId)), core.categories);
      if (saved) state.enabledCategories = saved.categories;
    } catch { /* 隐私模式不影响地图使用。 */ }
    state.points = pointData.points.map((point) => {
      const mapped = projectWorld(point.x, point.y);
      return { ...point, mx: mapped.x, my: mapped.y, searchText:`${point.id} ${point.name} ${point.genre} ${point.largeRegion} ${point.region} ${point.searchTerms || ""}`.toLowerCase() };
    });
    state.pointById = new Map(state.points.map((point) => [point.id, point]));
    state.layerPoints = state.points.filter(pointInActiveSpatialLayer);
    state.grid = new SpatialGrid(state.layerPoints.filter(inMapBounds));
    refreshLayerCategories();
    dom.largeRegion.textContent = core.meta.sceneName;
    buildFloorSwitch();
    buildFilters();
    bindEvents();
    collection.refresh(true);
    resizeCanvas(true);
    dom.loadingDetail.textContent = `正在铺开${state.activeSpatialLayerId === "surface" ? activeMap.label : activeSpatialLayer().name}`;
    if (state.activeSpatialLayerId === "surface") {
      await ensureSurfaceTiles();
    } else {
      await Promise.all([
        ensureSurfaceTiles(),
        loadActivePatches(),
        loadPreparedTiles("underground"),
      ]);
    }
    await loadPreparedTiles("unexplored");
    if (state.mapQuality === "hd" && (state.tileErrors || state.maskTiles.some(tile => !tile))) {
      state.qualityEpoch++;
      state.mapQuality = "standard";
      state.layerImages.clear(); state.layerImagePromises.clear();
      state.undergroundTiles = [];
      preparedTilePromises.clear();
      state.surfaceTilePromise = null;
      await Promise.all([ensureSurfaceTiles(), loadPreparedTiles("unexplored"),
        state.activeSpatialLayerId !== "surface" ? Promise.all([loadActivePatches(), loadPreparedTiles("underground")]) : null]);
      showMapNotice("高清地图暂时未能加载，已使用标准画质。");
    }
    state.qualityChanging = false;
    updateQualityButton();
    if (state.activeSpatialLayerId === "floor-3") focusActiveFloor();
    scheduleRender();
    dom.loading.classList.add("done");
    window.setTimeout(() => dom.loading.remove(), 400);
    if (state.tileErrors) showMapNotice("部分底图未能加载。", async () => { await loadTiles(); scheduleRender(); if (state.tileErrors) showMapNotice("部分底图仍未加载，请刷新重试。"); });
  } catch (error) {
    console.error(error);
    showFatal("地图暂时无法加载，请刷新重试。");
  }
}

function showMapNotice(message, retry) {
  let notice = $("#map-notice");
  if (!notice) { notice = document.createElement("div"); notice.id = "map-notice"; notice.className = "map-notice"; notice.setAttribute("role", "status"); dom.mapShell.append(notice); }
  notice.innerHTML = `<span>${escapeHtml(message)}</span>${retry ? '<div data-nrc-tag=button data-nrc-type="button">重试</div>' : ''}<div data-nrc-tag=button data-nrc-type="button" aria-label="关闭提示"><i class="fa-solid fa-xmark" aria-hidden="true"></i></div>`;
  if (retry) $("[data-nrc-tag=button]", notice).onclick = () => { notice.remove(); retry(); };
  $("[data-nrc-tag=button]:last-child", notice).onclick = () => notice.remove();
}

function showFatal(message, replace = true) {
  if (replace) {
    dom.loading.classList.add("is-error");
    dom.loading.setAttribute("role", "alert");
    dom.loadingTitle.textContent = "地图暂时无法展开";
    dom.loadingDetail.textContent = message;
  }
  else console.warn(message);
}

function refreshLayerCategories() {
  const counts = new Map();
  for (const point of state.layerPoints) {
    const key = categoryKey(point);
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  state.categories = state.allCategories
    .filter((category) => counts.has(category.id))
    .map((category) => ({ ...category, count: counts.get(category.id) }));
}

function activePatches() {
  if (state.activeSpatialLayerId === "surface") return [];
  const groups = new Map();
  for (const patch of state.spatialLayers) {
    if (!patchOnFloor(patch, state.activeSpatialLayerId)) continue;
    if (!groups.has(patch.groupId) || patch.id === state.focusedPatchId) groups.set(patch.groupId, patch);
  }
  return [...groups.values()];
}

async function loadActivePatches() {
  const patches = activePatches();
  await Promise.all(patches.map(patch => loadSpatialLayerImage(patch.id)));
  return patches.every(patch => state.layerImages.get(patch.id));
}

function updateSpatialLayerUI() {
  const layer = activeSpatialLayer();
  $$("[data-floor]").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.floor === layer.id)));
  dom.largeRegion.textContent = state.selectedPoint?.largeRegion || layer.groupName;
  dom.currentRegion.textContent = state.selectedPoint?.region || (layer.id === "surface" ? "拖动地图，开始探索" : layer.name);
}

function buildFloorSwitch() {
  const underground = state.spatialLayers.some(layer => layer.kind === "underground");
  $("#floor-switch").hidden = !underground;
  const floors = availableFloors(state.spatialLayers);
  $("#floor-switch").innerHTML = floors.map(id => `<div data-nrc-tag=button data-nrc-type="button" data-floor="${id}" aria-label="${FLOOR_LABELS[id]}" aria-pressed="false">${id === "surface" ? '<i class="fa-solid fa-map" aria-hidden="true"></i> ' : ''}<span class="floor-label-long">${FLOOR_LABELS[id]}</span><span class="floor-label-short">${FLOOR_LABELS[id].replace('地底', '')}</span></div>`).join("");
  updateSpatialLayerUI();
}

async function setSpatialLayer(layerId, updateUrl = true) {
  closePointPicker();
  if (!availableFloors(state.spatialLayers).includes(layerId)) return;
  cancelCameraMotion();
  state.hits = [];
  const request = ++state.layerRequest;
  state.activeSpatialLayerId = layerId;
  state.layerPoints = state.points.filter(pointInActiveSpatialLayer);
  state.grid = new SpatialGrid(state.layerPoints.filter(inMapBounds));
  refreshLayerCategories();
  state.selectedPoint = null;
  state.hoveredHit = null;
  closeDetails(false); hideTooltip(); closeSearch(false);
  buildFilters(); updateSpatialLayerUI();
  if (updateUrl) {
    const url = new URL(window.location.href);
    if (layerId === "surface") url.searchParams.delete("layer");
    else url.searchParams.set("layer", layerId);
    window.history.replaceState(null, "", url);
  }
  scheduleRender();
  const [loaded] = await Promise.all([loadActivePatches(), ensureSurfaceTiles(), layerId !== "surface" ? loadPreparedTiles("underground") : null]);
  if (state.layerRequest !== request) return;
  updateSpatialLayerUI();
  if (!loaded) showMapNotice("部分地底地图暂时未能加载，请刷新重试");
  scheduleRender(); updateScrim();
}

function buildFilters() {
  const expanded = new Set($$(".class-group.open", dom.filters).map(group => group.dataset.classId));
  const grouped = Map.groupBy
    ? Map.groupBy(state.categories, (category) => category.className)
    : state.categories.reduce((map, category) => {
        const list = map.get(category.className) || [];
        list.push(category);
        map.set(category.className, list);
        return map;
      }, new Map());
  const groups = [...grouped.entries()].sort(([a], [b]) => Number(!a) - Number(!b));
  dom.filters.innerHTML = groups.map(([className, categories], groupIndex) => {
    const classId = categories[0].classId;
    const count = categories.reduce((sum, category) => sum + category.count, 0);
    const children = categories.map((category) => `
      <div data-nrc-tag=label class="category-row" data-name="${escapeHtml(`${category.genre} ${category.className}`.toLowerCase())}">
        <span class="map-check"><input class="category-check" type="checkbox"${state.enabledCategories.has(category.id) ? " checked" : ""} data-category="${escapeHtml(category.id)}" /><i class="map-check-icon" aria-hidden="true"></i></span>
        ${detailIcon(category)}
        <span class="category-name" title="${escapeHtml(category.genre)}">${escapeHtml(category.genre)}${isCollectible(category) ? `<div class="category-collection-count" data-collection-category="${escapeHtml(category.id)}" hidden></div>` : ''}</span><small>${category.count}</small>
      </div>`).join("");
    if (!className) return `<div class="category-independent">${children}</div>`;
    const open = expanded.has(String(classId)) || (!dom.filters.children.length && groupIndex === 0);
    return `<div data-nrc-tag=section class="class-group${open ? " open" : ""}" data-class-id="${classId}" data-name="${escapeHtml(className.toLowerCase())}">
      <div class="class-row"><span class="map-check"><input class="class-check" type="checkbox" checked data-class-id="${classId}" aria-label="选择全部${escapeHtml(className)}" /><i class="map-check-icon" aria-hidden="true"></i></span>
      <div data-nrc-tag=button class="class-expand" data-nrc-type="button" aria-expanded="${open}" aria-controls="categories-${classId}"><strong>${escapeHtml(className)}</strong><small>${count.toLocaleString("zh-CN")}</small><i class="ui-icon class-arrow fa-solid fa-chevron-right" aria-hidden="true"></i></div></div>
      <div class="category-list" id="categories-${classId}"${open ? "" : " hidden"}>${children}</div></div>`;
  }).join("");
  $("#filter-presets").innerHTML = PRESETS.filter(preset => state.categories.some(preset.match)).map(preset => {
    const categories = state.categories.filter(preset.match);
    const icon = state.categoryById.get(`${categories[0]?.classId}:${preset.genre}`)?.icon || categories[0]?.icon;
    return `<div data-nrc-tag=button class="preset-button" data-nrc-type="button" data-preset="${preset.id}" aria-pressed="false">${icon ? detailIcon({ icon, genre:preset.label }) : ""}<span><strong>${preset.label}</strong><small>${preset.hint}</small></span></div>`;
  }).join("");
  updateClassCheckboxes();
  updateVisibleTotal();
  filterCategories(dom.categorySearch.value);
}

function updateClassCheckboxes() {
  $$(".class-group", dom.filters).forEach((group) => {
    const children = $$(".category-check", group);
    const checked = children.filter((input) => input.checked).length;
    const parent = $(".class-check", group);
    parent.checked = checked === children.length;
    parent.indeterminate = checked > 0 && checked < children.length;
  });
  updateSelectionSummary();
  syncSelectedPoint();
}

function syncSelectedPoint() {
  closePointPicker();
  hideTooltip();
  if (state.selectedPoint && (state.mapSearch ? !state.mapSearch.ids.has(state.selectedPoint.id) : !state.enabledCategories.has(categoryKey(state.selectedPoint)))) closeDetails(false);
}

function updateSelectionSummary() {
  const selected = state.categories.filter(c => state.enabledCategories.has(c.id));
  const count = state.layerPoints.filter(p => state.enabledCategories.has(categoryKey(p)) && matchesCollection(p)).length;
  $("#selection-summary").textContent = state.mapSearch ? "正在查看搜索结果 · 点击分类可退出搜索" : `已选 ${selected.length} 类 · 本层 ${count.toLocaleString("zh-CN")} 个点位`;
  let label = selected.length === state.categories.length ? "全部点位" : selected.length ? "自定义筛选" : "未选择点位";
  $$("[data-preset]").forEach(button => {
    const ids = presetCategories(state.categories, button.dataset.preset);
    const active = !state.mapSearch && ids.size > 0 && ids.size === selected.length && selected.every(c => ids.has(c.id));
    button.setAttribute("aria-pressed", String(active));
    if (active) label = PRESETS.find(p => p.id === button.dataset.preset).label;
  });
  $("#active-filter-label").textContent = state.mapSearch ? "搜索结果" : label;
  if (state.collectionFilter !== 'all') $('#active-filter-label').textContent += state.collectionFilter === 'collected' ? ' · 已收集' : ' · 未收集';
  $("#map-search-filter").hidden = !state.mapSearch;
  if (state.mapSearch) $("#map-search-filter span").textContent = `${state.mapSearch.query} · 本层 ${state.layerPoints.filter(p => state.mapSearch.ids.has(p.id) && matchesCollection(p)).length} 个`;
  updateCollectionUI();
}

function savePreferences() {
  try {
    localStorage.setItem(preferenceKey(activeMapId), JSON.stringify({ version:1, categories:[...state.enabledCategories] }));
  } catch { $(".panel-footer span").textContent = "当前浏览器无法保存筛选"; }
}

function applyPreset(presetId) {
  clearMapSearch();
  const ids = presetCategories(state.categories, presetId);
  if (!state.categories.some(c => ids.has(c.id) && isCollectible(c))) state.collectionFilter = 'all';
  for (const c of state.categories) {
    if (ids.has(c.id)) state.enabledCategories.add(c.id);
    else state.enabledCategories.delete(c.id);
  }
  dom.categorySearch.value = "";
  $$(".category-check", dom.filters).forEach(input => { input.checked = state.enabledCategories.has(input.dataset.category); });
  $$(".class-group", dom.filters).forEach(group => { group.classList.toggle("open", $$(".category-check", group).some(input => input.checked)); });
  updateClassCheckboxes(); filterCategories(""); savePreferences(); scheduleRender();
}

function updateVisibleTotal(viewCount = null) {
  if (viewCount !== null) {
    dom.visibleCount.textContent = viewCount.toLocaleString("zh-CN");
    $("#map-empty").hidden = viewCount > 0;
    const selected = state.mapSearch || state.categories.some(c => state.enabledCategories.has(c.id));
    $("#empty-title").textContent = !selected ? "还没有选择点位" : "当前视野没有匹配点位";
    $("#empty-description").textContent = !selected ? "从探索点位开始，或在筛选里选择想找的内容。" : "试试缩小地图、切换楼层，或换一种探索方式。";
    return;
  }
  const count = state.categories
    .filter((category) => state.enabledCategories.has(category.id))
    .reduce((sum, category) => sum + category.count, 0);
  dom.visibleCount.textContent = count.toLocaleString("zh-CN");
}

function applyCategoryInput(input) {
  clearMapSearch();
  if (input.checked) { state.enabledCategories.add(input.dataset.category); }
  else state.enabledCategories.delete(input.dataset.category);
  updateClassCheckboxes();
  updateVisibleTotal();
  savePreferences();
  scheduleRender();
}

function toggleClass(group, checked) {
  clearMapSearch();
  $$(".category-check", group).forEach((input) => {
    input.checked = checked;
    if (checked) state.enabledCategories.add(input.dataset.category);
    else state.enabledCategories.delete(input.dataset.category);
  });
  updateClassCheckboxes();
  updateVisibleTotal();
  savePreferences();
  scheduleRender();
}

function filterCategories(query) {
  const normalized = query.trim().toLowerCase();
  $$(".class-group", dom.filters).forEach((group) => {
    let matches = 0;
    $$(".category-row", group).forEach((row) => {
      const visible = !normalized || row.dataset.name.includes(normalized);
      row.hidden = !visible;
      if (visible) matches += 1;
    });
    const groupMatch = !normalized || group.dataset.name.includes(normalized) || matches > 0;
    group.hidden = !groupMatch;
    group.classList.toggle("search-match", Boolean(normalized && matches));
    const open = Boolean(normalized && matches) || group.classList.contains("open");
    $(".category-list", group).hidden = !open;
    $(".class-expand", group).setAttribute("aria-expanded", String(open));
  });
  $$(".category-independent", dom.filters).forEach(group => {
    const rows = $$(".category-row", group);
    rows.forEach(row => { row.hidden = Boolean(normalized && !row.dataset.name.includes(normalized)); });
    group.hidden = rows.every(row => row.hidden);
  });
  $("#filter-empty").hidden = $$(".class-group,.category-independent", dom.filters).some(group => !group.hidden);
}

function bindEvents() {
  $('#collection-login').addEventListener('click',loginCollection);
  $('#collection-retry').addEventListener('click',() => collection.refresh(true));
  $('#collection-types').addEventListener('click',selectCollectibleCategories);
  $('#collection-panel').addEventListener('click',event => {
    const control = event.target.closest('[data-collection-filter]');
    if (control) setCollectionFilter(control.dataset.collectionFilter);
  });
  $('#collection-panel').addEventListener('keydown',event => {
    if (['Enter',' '].includes(event.key) && event.target.matches('[data-collection-filter]')) { event.preventDefault(); event.target.click(); }
  });
  dom.detailContent.addEventListener('click',event => {
    const control = event.target.closest('[data-collection-toggle]');
    if (!control || !isCollectible(state.pointById.get(control.dataset.collectionToggle))) return;
    if (!collection.uid || collection.authFailed) loginCollection();
    else if (!collection.available) collection.refresh(true);
    else collection.toggle(control.dataset.collectionToggle);
  });
  dom.detailContent.addEventListener('keydown',event => {
    if (['Enter',' '].includes(event.key) && event.target.matches('[data-collection-toggle]')) { event.preventDefault(); event.target.click(); }
  });
  window.addEventListener('focus',() => collection.refresh());
  window.addEventListener('beforeunload',event => {
    if (collection.dirty) { collection.flush(); event.preventDefault(); event.returnValue = ''; }
  });
  $("#clear-map-search").addEventListener("click", () => clearMapSearch());
  $("#point-picker-close").addEventListener("click", () => closePointPicker(true));
  $("#point-picker-list").addEventListener("click", event => {
    const button = event.target.closest("[data-picker-point]");
    if (!button) return;
    closePointPicker();
    const point = state.pointById.get(button.dataset.pickerPoint);
    if (pointSelectable(point)) focusPointAcrossLayers(point);
  });
  $("#point-picker").addEventListener("keydown", event => {
    const buttons = $$("[data-picker-point]");
    const index = buttons.indexOf(document.activeElement);
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      buttons[(index + (event.key === "ArrowDown" ? 1 : -1) + buttons.length) % buttons.length]?.focus();
    }
  });
  document.addEventListener("pointerdown", event => {
    if (!event.target.closest("#point-picker")) closePointPicker();
  });
  window.addEventListener("resize", () => resizeCanvas(false));
  new ResizeObserver(() => resizeCanvas(false)).observe(dom.mapShell);
  new ResizeObserver(() => {
    $(".app-shell").style.setProperty("--detail-height", `${dom.details.getBoundingClientRect().height}px`);
  }).observe(dom.details);
  dom.layerPanel.inert = root.clientWidth <= 760;
  syncPanels();
  $(".map-gesture-hint").textContent = matchMedia("(pointer:coarse)").matches ? "单指拖动 · 双指缩放" : "拖动探索 · 滚轮缩放";
  dom.canvas.addEventListener("pointerdown", onPointerDown);
  dom.canvas.addEventListener("pointermove", onPointerMove);
  dom.canvas.addEventListener("pointerup", onPointerUp);
  dom.canvas.addEventListener("pointercancel", event => onPointerUp(event, true));
  dom.canvas.addEventListener("lostpointercapture", event => onPointerUp(event, true));
  window.addEventListener("blur", () => {
    state.pointers.clear(); state.pinch = null; state.dragging = false;
    dom.mapShell.classList.remove("dragging"); cancelCameraMotion(); hideTooltip();
  });
  matchMedia("(prefers-reduced-motion:reduce)").addEventListener("change", event => { if (event.matches) cancelCameraMotion(); });
  dom.canvas.addEventListener("pointerleave", () => {
    if (!state.dragging) hideTooltip();
  });
  dom.canvas.addEventListener("wheel", onWheel, { passive: false });

  dom.filters.addEventListener("change", (event) => {
    if (event.target.matches(".category-check")) applyCategoryInput(event.target);
    if (event.target.matches(".class-check")) toggleClass(event.target.closest(".class-group"), event.target.checked);
  });
  dom.filters.addEventListener("click", (event) => {
    const button = event.target.closest(".class-expand");
    if (!button) return;
    const group = button.closest(".class-group");
    const open = button.getAttribute("aria-expanded") !== "true";
    group.classList.toggle("open", open);
    group.classList.remove("search-match");
    $(".category-list", group).hidden = !open;
    button.setAttribute("aria-expanded", String(open));
  });
  dom.categorySearch.addEventListener("input", () => filterCategories(dom.categorySearch.value));
  $("#select-all").addEventListener("click", () => setAllCategories(true));
  $("#select-none").addEventListener("click", () => setAllCategories(false));
  $("#filter-presets").addEventListener("click", event => {
    const button = event.target.closest("[data-preset]");
    if (button) applyPreset(button.dataset.preset);
  });
  $("#empty-reset").addEventListener("click", () => applyPreset("explore"));
  $("#empty-fit").addEventListener("click", resetView);

  dom.globalSearch.addEventListener("input", updateSearchResults);
  $(".topbar").addEventListener("focusin", event => {
    if (event.target.id !== "layer-toggle" && root.clientWidth <= 760 && dom.layerPanel.classList.contains("open")) closeLayers();
  });
  dom.globalSearch.addEventListener("focus", () => { if (dom.globalSearch.value.trim()) updateSearchResults(); });
  dom.globalSearch.addEventListener("keydown", (event) => {
    const results = $$(".search-result", dom.searchResults);
    if ((event.key === "ArrowDown" || event.key === "ArrowUp") && results.length) {
      event.preventDefault();
      state.searchIndex = state.searchIndex < 0 ? (event.key === "ArrowDown" ? 0 : results.length - 1) : (state.searchIndex + (event.key === "ArrowDown" ? 1 : -1) + results.length) % results.length;
      results.forEach((button, index) => { button.classList.toggle("active", index === state.searchIndex); button.setAttribute("aria-selected", String(index === state.searchIndex)); });
      const selected = results[state.searchIndex];
      dom.globalSearch.setAttribute("aria-activedescendant", selected.id);
      selected.scrollIntoView({ block:"nearest" });
    }
    if (event.key === "Enter" && !dom.searchResults.hidden) {
      event.preventDefault();
      (results[state.searchIndex] || results[0])?.click();
    }
  });
  dom.searchResults.addEventListener("click", (event) => {
    if (event.target.closest("[data-search-map]")) return showSearchOnMap();
    const button = event.target.closest("[data-search-point]");
    if (button) focusPointAcrossLayers(state.pointById.get(button.dataset.searchPoint), true, dom.globalSearch.value);
  });
  document.addEventListener("keydown", (event) => {
    if (!root.contains(event.target)) return;
    const editing = event.target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName);
    if (event.key === "Escape") {
      if (!$("#point-picker").hidden) { closePointPicker(true); return; }
      if (!dom.searchResults.hidden) closeSearch(false);
      else if (root.clientWidth <= 760 && dom.layerPanel.classList.contains("open")) closeLayers();
      else closeDetails();
    }
    if (editing || event.ctrlKey || event.metaKey || event.altKey || dom.mapShell.inert) return;
    if (event.key === "/") { event.preventDefault(); dom.globalSearch.focus(); }
    if (event.key === "+" || event.key === "=") { event.preventDefault(); zoomBy(1.35); }
    if (event.key === "-") { event.preventDefault(); zoomBy(1 / 1.35); }
    if (event.target === dom.canvas) {
      const directions = { ArrowLeft:[-1,0], ArrowRight:[1,0], ArrowUp:[0,-1], ArrowDown:[0,1] };
      const direction = directions[event.key];
      if (direction) { event.preventDefault(); cancelCameraMotion(); state.camera.x += direction[0] * 80 / state.camera.scale; state.camera.y += direction[1] * 80 / state.camera.scale; constrainCamera(); scheduleRender(); }
      if (event.key === "0") resetView();
    }
  });
  document.addEventListener("click", event => { if (!event.target.closest(".search-box")) closeSearch(false); });

  $("#map-quality-toggle").addEventListener("click", () => setMapQuality(state.mapQuality === "hd" ? "standard" : "hd"));
  $("#zoom-in").addEventListener("click", () => zoomBy(1.35));
  $("#zoom-out").addEventListener("click", () => zoomBy(1 / 1.35));
  $("#reset-view").addEventListener("click", resetView);
  $(".brand").addEventListener("click", (event) => { event.preventDefault(); resetView(); });
  $("#wiki-home").addEventListener("click", () => window.location.assign("https://wiki.biligame.com/nrc/首页"));
  $("#wiki-home").addEventListener("keydown", event => {
    if (event.key === "Enter" && !event.repeat) { event.preventDefault(); event.currentTarget.click(); }
  });
  dom.mapSelect.addEventListener("change", () => {
    const url = new URL(window.location.href);
    url.searchParams.set("map", dom.mapSelect.value);
    url.searchParams.delete("layer");
    window.location.assign(url);
  });
  $("#detail-close").addEventListener("click", () => closeDetails());
  $("#quality-open").addEventListener("click", renderQualityDetails);
  $$("[data-floor]").forEach(button => button.addEventListener("click", () => {
    chooseFloor(button.dataset.floor);
  }));
  dom.detailContent.addEventListener("input", event => {
    if (event.target.id === "habitat-search") updateHabitatPets(event.target.value);
  });
  dom.detailContent.addEventListener("click", (event) => {
    const floorLink = event.target.closest("[data-detail-floor]");
    if (floorLink) {
      const point = state.pointById.get(floorLink.dataset.detailFloor);
      if (pointSelectable(point)) focusPointAcrossLayers(point, false, "", true);
      return;
    }
    if (event.target.closest("[data-habitat-clear]")) {
      $("#habitat-search").value = ""; updateHabitatPets(""); $("#habitat-search").focus({preventScroll:true}); return;
    }
    const more = event.target.closest("[data-detail-more]");
    if (more) {
      const container = more.closest(".detail-expandable");
      const expanded = container.classList.toggle("is-expanded");
      more.setAttribute("aria-expanded", String(expanded));
      more.innerHTML = `${expanded ? "收起" : `展开全部 ${more.dataset.detailMore} 项`} <i class="fa-solid fa-chevron-${expanded ? "up" : "down"}" aria-hidden="true"></i>`;
      return;
    }
    const tab = event.target.closest("[data-picnic-tab]");
    if (tab) {
      const section = tab.closest(".picnic-section");
      $$("[data-picnic-tab]", section).forEach(control => control.setAttribute("aria-pressed", String(control === tab)));
      $$("[data-picnic-panel]", section).forEach(panel => { panel.hidden = panel.dataset.picnicPanel !== tab.dataset.picnicTab; });
    }
    const period = event.target.closest('[data-dungeon-period]');
    if (period) {
      const section = period.closest('.timed-dungeon');
      $$('[data-dungeon-period]', section).forEach(control => control.setAttribute('aria-pressed', String(control === period)));
      $$('[data-dungeon-room]', section).forEach(panel => { panel.hidden = panel.dataset.dungeonRoom !== period.dataset.dungeonPeriod; });
    }
  });
  dom.detailContent.addEventListener("keydown", event => {
    if (!event.defaultPrevented && ["Enter", " "].includes(event.key) && event.target.matches("[data-detail-more],[data-picnic-tab],[data-detail-floor],[data-dungeon-period]")) {
      event.preventDefault(); event.target.click();
    }
  });
  $("#layer-toggle").addEventListener("click", () => {
    const open = root.clientWidth <= 760 ? dom.layerPanel.classList.contains("open") : !$(".app-shell").classList.contains("filters-collapsed");
    if (open) closeLayers(); else openLayers();
  });
  $("#layer-close").addEventListener("click", closeLayers);
  $("#filter-done").addEventListener("click", closeLayers);
  dom.scrim.addEventListener("click", closeLayers);
  matchMedia("(max-width:760px)").addEventListener("change", () => { dom.layerPanel.classList.remove("open"); syncPanels(); });
}

function setAllCategories(enabled) {
  clearMapSearch();
  for (const category of state.categories) {
    if (enabled) state.enabledCategories.add(category.id);
    else state.enabledCategories.delete(category.id);
  }
  $$(".category-check", dom.filters).forEach((input) => { input.checked = enabled; });
  updateClassCheckboxes(); updateVisibleTotal(); savePreferences(); scheduleRender();
}

function clearMapSearch() {
  if (!state.mapSearch) return;
  state.mapSearch = null;
  updateClassCheckboxes(); scheduleRender();
}

function fitMapPoints(points) {
  if (!points.length) return;
  const xs = points.map(p => p.mx), ys = points.map(p => p.my);
  const left = Math.min(...xs), right = Math.max(...xs), top = Math.min(...ys), bottom = Math.max(...ys);
  const scale = Math.min(state.camera.fitScale * 16, state.viewport.width * .8 / Math.max(right-left, 150), state.viewport.height * .72 / Math.max(bottom-top, 150));
  animateCamera({ x:(left+right)/2, y:(top+bottom)/2, scale:Math.max(state.camera.fitScale,scale) });
}

function showSearchOnMap() {
  const query = dom.globalSearch.value.trim();
  if (!query || !state.searchMatches.length) return;
  const matches = state.searchMatches;
  // Keep the full query set so changing collection status can reveal other matches.
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  state.mapSearch = { query, ids:new Set(state.points.filter(point => terms.every(term => point.searchText.includes(term))).map(point => point.id)) };
  enablePointLayer();
  state.focusedPatchId = null;
  setSpatialLayer("surface");
  closeSearch();
  if (root.clientWidth <= 760) closeLayers();
  updateSelectionSummary();
  fitMapPoints(matches);
}

function chooseFloor(id) {
  state.focusedPatchId = null;
  setSpatialLayer(id);
  if (id === "floor-3") focusActiveFloor();
}

function focusActiveFloor() {
  const corners = activePatches().flatMap(patch => {
    const rect = activeLayerMapRect(patch);
    return [{mx:rect.x,my:rect.y}, {mx:rect.x+rect.width,my:rect.y+rect.height}];
  });
  fitMapPoints(corners);
}

function updateSearchResults() {
  const query = dom.globalSearch.value.trim().toLowerCase();
  if (!query) return closeSearch(false);
  const terms = query.split(/\s+/).filter(Boolean);
  const scored = [];
  for (const point of state.points) {
    if (!matchesCollection(point)) continue;
    const haystack = point.searchText;
    if (!terms.every((term) => haystack.includes(term))) continue;
    let score = 0;
    if (point.name.toLowerCase() === query) score += 100;
    if (point.name.toLowerCase().startsWith(query)) score += 30;
    if (point.genre.toLowerCase() === query) score += 15;
    // Searching for a pet should lead to its habitat before indirect fruit
    // references in sanctuary details, regardless of the camera position.
    const pets = state.core.details[point.id]?.habitat?.pets || [];
    if (pets.some(pet => pet.name.toLowerCase() === query)) score += 50;
    if (pointInActiveSpatialLayer(point)) score += 10;
    if (inMapBounds(point)) score += 5;
    scored.push({ point, score, distance:Math.hypot(point.mx - state.camera.x, point.my - state.camera.y) });
  }
  scored.sort((a, b) => b.score - a.score || a.distance - b.distance || a.point.id.localeCompare(b.point.id));
  state.searchMatches = scored.map(item => item.point);
  const matches = scored.slice(0, 50).map(({ point }) => point);
  state.searchIndex = -1;
  dom.globalSearch.removeAttribute("aria-activedescendant");
  dom.searchResults.innerHTML = `<div class="search-heading" role="presentation">找到 ${scored.length} 个点位${scored.length > 50 ? " · 显示前 50 项" : ""}<small>搜索所有类型与楼层 · 同类结果优先显示附近点位</small>${scored.length ? `<div data-nrc-tag=button data-nrc-type="button" class="search-map-action" data-search-map><i class="fa-solid fa-map-location-dot" aria-hidden="true"></i> 在地图上查看全部 ${scored.length} 个结果</div>` : ""}</div>` + (matches.map((point, index) => {
    const layer = state.spatialLayerById.get(point.mapLayerId);
    const pets = state.core.details[point.id]?.habitat?.pets || [];
    const petQuery = habitatQuery(pets, query);
    const matched = petQuery ? filterHabitatPets(pets, petQuery) : [];
    const petNames = [...new Set(matched.map(p => p.name))];
    return `<div data-nrc-tag=button class="search-result" data-nrc-type="button" role="option" aria-selected="false" id="search-point-${index}" data-search-point="${escapeHtml(point.id)}">
    ${matched[0]?.icon ? detailIcon({...matched[0], iconKind:"portrait"}) : detailIcon(point)}
    <span><strong>${escapeHtml(point.name)}</strong>${matched.length ? `<span class="search-pet-match">${escapeHtml(petNames.slice(0,3).join(" / "))}${petNames.length > 3 ? "…" : ""}</span>` : ""}<small>${escapeHtml(point.genre)} · ${escapeHtml(layer?.name || point.region)} · ${escapeHtml(point.largeRegion)} / ${escapeHtml(point.region)}</small></span>${collectedPoint(point) ? '<i class="fa-solid fa-circle-check collection-result-check" aria-label="已收集"></i>' : ''}
  </div>`;
  }).join("") || `<div class="search-empty">没找到相关点位。试试精灵名、区域名或「宝箱」。</div>`);
  dom.searchResults.hidden = false;
  dom.globalSearch.setAttribute("aria-expanded", "true");
}

function closeSearch(clear = true) {
  dom.searchResults.hidden = true;
  dom.globalSearch.setAttribute("aria-expanded", "false");
  dom.globalSearch.removeAttribute("aria-activedescendant");
  if (clear) dom.globalSearch.value = "";
}

function openDetails() {
  if (root.clientWidth <= 760) dom.layerPanel.classList.remove("open");
  else if (root.clientWidth <= 1100 && !$(".app-shell").classList.contains("filters-collapsed")) {
    $(".app-shell").classList.add("filters-collapsed");
    resizeCanvas(false);
  }
  dom.details.classList.add("open");
  dom.details.setAttribute("aria-hidden", "false");
  dom.details.inert = false;
  dom.details.scrollTop = 0;
  $(".app-shell").classList.add("has-details");
  updateScrim();
  $("#detail-close").focus({ preventScroll:true });
}

function closeDetails(restoreFocus = true) {
  pointComments.close();
  const containedFocus = dom.details.contains(document.activeElement);
  dom.details.classList.remove("open");
  dom.details.setAttribute("aria-hidden", "true");
  dom.details.inert = true;
  $(".app-shell").classList.remove("has-details");
  state.selectedPoint = null;
  scheduleRender(); updateScrim();
  if (restoreFocus && containedFocus) dom.canvas.focus({ preventScroll:true });
}

function openLayers() {
  if (root.clientWidth <= 760) { closeDetails(false); dom.layerPanel.classList.add("open"); }
  else $(".app-shell").classList.remove("filters-collapsed");
  closeSearch(false); syncPanels();
  $("#layer-close").focus({ preventScroll:true });
}
function closeLayers() {
  const containedFocus = dom.layerPanel.contains(document.activeElement);
  if (root.clientWidth <= 760) dom.layerPanel.classList.remove("open");
  else $(".app-shell").classList.add("filters-collapsed");
  syncPanels();
  if (containedFocus) $("#layer-toggle").focus({ preventScroll:true });
}
function syncPanels() {
  const mobile = root.clientWidth <= 760;
  const mobileLayers = mobile && dom.layerPanel.classList.contains("open");
  const expanded = mobile ? mobileLayers : !$(".app-shell").classList.contains("filters-collapsed");
  dom.layerPanel.inert = !expanded;
  dom.layerPanel.setAttribute("aria-hidden", String(!expanded));
  $("#layer-toggle").setAttribute("aria-expanded", String(expanded));
  $("#layer-toggle").setAttribute("aria-label", expanded ? "收起筛选" : "打开筛选");
  dom.scrim.hidden = !mobileLayers;
  dom.mapShell.inert = mobileLayers;
}
function updateScrim() { syncPanels(); }

function resizeCanvas(initial) {
  closePointPicker();
  if (!state.core) return;
  cancelCameraMotion();
  const rect = dom.mapShell.getBoundingClientRect();
  const previousFit = state.camera.fitScale || 1;
  const zoomRatio = initial ? 1 : state.camera.scale / previousFit;
  state.viewport.width = Math.max(1, rect.width);
  state.viewport.height = Math.max(1, rect.height);
  // Preserve Retina marker edges, while bounding the main canvas to 4M pixels.
  const dpr = Math.min(window.devicePixelRatio || 1, 3, Math.sqrt(4000000 / (state.viewport.width * state.viewport.height)));
  if (state.viewport.dpr !== dpr) state.markerCache.clear();
  state.viewport.dpr = dpr;
  dom.canvas.width = Math.round(rect.width * state.viewport.dpr);
  dom.canvas.height = Math.round(rect.height * state.viewport.dpr);
  dom.canvas.style.width = `${rect.width}px`;
  dom.canvas.style.height = `${rect.height}px`;
  const mapRect = SURFACE_MAP_RECT;
  state.camera.fitScale = Math.min(rect.width / mapRect.width, rect.height / mapRect.height) * 0.9;
  state.camera.scale = state.camera.fitScale * (initial ? (root.clientWidth <= 760 ? 1.6 : 1.1) : zoomRatio);
  if (initial) {
    state.camera.x = mapRect.x + mapRect.width / 2;
    state.camera.y = mapRect.y + mapRect.height / 2;
  }
  constrainCamera(); scheduleRender(); updateScrim();
}

function resetView() {
  const rect = SURFACE_MAP_RECT;
  animateCamera({ x:rect.x + rect.width / 2, y:rect.y + rect.height / 2, scale:state.camera.fitScale });
}

function cancelCameraMotion() {
  if (state.cameraAnimation !== null) cancelAnimationFrame(state.cameraAnimation);
  state.cameraAnimation = null;
}

function animateCamera(target) {
  cancelCameraMotion();
  if (matchMedia("(prefers-reduced-motion:reduce)").matches) {
    Object.assign(state.camera, target); constrainCamera(); scheduleRender(); return;
  }
  const start = { ...state.camera }, began = performance.now();
  const frame = now => {
    const progress = Math.min(1, (now - began) / 240), eased = 1 - (1 - progress) ** 3;
    for (const key of ["x", "y", "scale"]) state.camera[key] = start[key] + (target[key] - start[key]) * eased;
    constrainCamera(); scheduleRender();
    state.cameraAnimation = progress < 1 ? requestAnimationFrame(frame) : null;
  };
  state.cameraAnimation = requestAnimationFrame(frame);
}

function zoomBy(factor, anchor = { x: state.viewport.width / 2, y: state.viewport.height / 2 }) {
  const before = screenToMap(anchor.x, anchor.y);
  const scale = Math.max(state.camera.fitScale * .72, Math.min(state.camera.fitScale * 24, state.camera.scale * factor));
  animateCamera({ scale, x:before.x - (anchor.x - state.viewport.width / 2) / scale, y:before.y - (anchor.y - state.viewport.height / 2) / scale });
}

function setZoom(scale, anchor) {
  cancelCameraMotion();
  const before = screenToMap(anchor.x, anchor.y);
  state.camera.scale = Math.max(state.camera.fitScale * 0.72, Math.min(state.camera.fitScale * 24, scale));
  const after = screenToMap(anchor.x, anchor.y);
  state.camera.x += before.x - after.x;
  state.camera.y += before.y - after.y;
  constrainCamera(); scheduleRender();
}

function constrainCamera() {
  const rect = SURFACE_MAP_RECT;
  const halfX = state.viewport.width / 2 / state.camera.scale;
  const halfY = state.viewport.height / 2 / state.camera.scale;
  // 详情打开时给边缘点位留出移入可操作区域的空间，否则全图居中约束会把它压在面板下。
  if (state.selectedPoint && dom.details.classList.contains("open")) {
    const mobile = root.clientWidth <= 760;
    const panel = dom.details.getBoundingClientRect();
    const extraX = mobile ? 0 : (panel.width + 24) / 2 / state.camera.scale;
    const extraY = mobile ? panel.height / 2 / state.camera.scale : 0;
    state.camera.x = Math.max(rect.x - halfX * .25, Math.min(rect.x + rect.width + extraX, state.camera.x));
    state.camera.y = Math.max(rect.y - halfY * .25, Math.min(rect.y + rect.height + extraY, state.camera.y));
    return;
  }
  const paddingX = Math.min(halfX * 0.7, rect.width * 0.075);
  const paddingY = Math.min(halfY * 0.7, rect.height * 0.075);
  if (halfX >= rect.width / 2) state.camera.x = rect.x + rect.width / 2;
  else state.camera.x = Math.max(rect.x + paddingX, Math.min(rect.x + rect.width - paddingX, state.camera.x));
  if (halfY >= rect.height / 2) state.camera.y = rect.y + rect.height / 2;
  else state.camera.y = Math.max(rect.y + paddingY, Math.min(rect.y + rect.height - paddingY, state.camera.y));
}

function onWheel(event) {
  closePointPicker();
  event.preventDefault();
  const rect = dom.canvas.getBoundingClientRect();
  const delta = event.deltaY * (event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? state.viewport.height : 1);
  const factor = Math.exp(-Math.max(-240, Math.min(240, delta)) * 0.0015);
  setZoom(state.camera.scale * factor, { x: event.clientX - rect.left, y: event.clientY - rect.top });
}

function pointerPosition(event) {
  const rect = dom.canvas.getBoundingClientRect();
  return { x: event.clientX - rect.left, y: event.clientY - rect.top };
}

function onPointerDown(event) {
  if (event.button !== 0) return;
  cancelCameraMotion();
  dom.canvas.focus({ preventScroll:true });
  const point = pointerPosition(event);
  state.pointers.set(event.pointerId, point);
  if (state.pointers.size === 1) state.gestureMoved = false;
  if (state.pointers.size === 2) {
    const [a, b] = [...state.pointers.values()];
    state.pinch = { scale:state.camera.scale, distance:Math.hypot(a.x-b.x, a.y-b.y), anchor:screenToMap((a.x+b.x)/2, (a.y+b.y)/2) };
    state.gestureMoved = true;
  }
  state.dragging = true;
  state.dragStart = { pointer: point, camera: { x: state.camera.x, y: state.camera.y } };
  state.dragDistance = 0;
  dom.mapShell.classList.add("dragging");
  dom.canvas.setPointerCapture(event.pointerId);
}

function onPointerMove(event) {
  const point = pointerPosition(event);
  updateCursorLocation(point);
  if (state.pointers.has(event.pointerId)) state.pointers.set(event.pointerId, point);
  if (state.pointers.size >= 2 && state.pinch) {
    const [a,b] = [...state.pointers.values()];
    Object.assign(state.camera, pinchTransform(state.pinch, a, b, state.viewport, state.camera.fitScale * .72, state.camera.fitScale * 24));
    constrainCamera(); hideTooltip(); scheduleRender(); return;
  }
  if (state.dragging) {
    const dx = point.x - state.dragStart.pointer.x;
    const dy = point.y - state.dragStart.pointer.y;
    state.dragDistance = Math.max(state.dragDistance, Math.hypot(dx, dy));
    if (state.dragDistance >= 6) state.gestureMoved = true;
    state.camera.x = state.dragStart.camera.x - dx / state.camera.scale;
    state.camera.y = state.dragStart.camera.y - dy / state.camera.scale;
    constrainCamera(); hideTooltip(); scheduleRender();
  } else {
    updateHover(point);
  }
}

function onPointerUp(event, cancelled = false) {
  if (!state.pointers.has(event.pointerId)) return;
  const point = pointerPosition(event);
  state.pointers.delete(event.pointerId);
  if (cancelled) state.gestureMoved = true;
  if (!state.pointers.size && !state.gestureMoved && state.dragDistance < 6) {
    const hit = hitAt(point);
    const candidates = pointsAtHit(state.hits.filter(hit => pointSelectable(hit.point)), point);
    if (candidates.length > 1) showPointPicker(candidates, point);
    else activateHit(hit);
  }
  state.dragging = state.pointers.size > 0;
  state.pinch = null;
  if (state.dragging) state.dragStart = { pointer:[...state.pointers.values()][0], camera:{ x:state.camera.x, y:state.camera.y } };
  dom.mapShell.classList.toggle("dragging", state.dragging);
  try { dom.canvas.releasePointerCapture(event.pointerId); } catch { /* already released */ }
}

function hitAt(position) {
  for (let index = state.hits.length - 1; index >= 0; index -= 1) {
    const hit = state.hits[index];
    if (pointSelectable(hit.point) && Math.hypot(position.x - hit.x, position.y - hit.y) <= hit.radius) return hit;
  }
  return null;
}

function pointSelectable(point) {
  return Boolean(point && pointInActiveSpatialLayer(point)
    && matchesCollection(point)
    && (state.mapSearch ? state.mapSearch.ids.has(point.id) : state.enabledCategories.has(categoryKey(point))));
}

function activateHit(hit) {
  if (!hit) return closeDetails();
  focusPointAcrossLayers(hit.point);
}

function closePointPicker(restoreFocus = false) {
  const picker = $("#point-picker");
  if (!picker || picker.hidden) return;
  picker.hidden = true;
  if (restoreFocus) dom.canvas.focus({ preventScroll:true });
}

function showPointPicker(points, position) {
  cancelCameraMotion(); hideTooltip(); closeDetails(false);
  const picker = $("#point-picker");
  const sorted = points.slice().sort((a, b) => a.name.localeCompare(b.name, "zh-CN") || a.id.localeCompare(b.id));
  $(".point-picker-heading strong").textContent = new Set(sorted.map(p => p.genre)).size === 1 ? `${sorted[0].genre} · ${sorted.length} 处` : `选择点位 · ${sorted.length} 处`;
  $("#point-picker-list").innerHTML = sorted.map(point => `<div data-nrc-tag=button data-nrc-type="button" data-picker-point="${escapeHtml(point.id)}">
    ${detailIcon(point)}<span><strong>${escapeHtml(point.name)}</strong><small>${escapeHtml(point.genre)} · ${escapeHtml(state.spatialLayerById.get(point.mapLayerId)?.name || "大地图")}</small></span>
    <i class="fa-solid fa-chevron-right" aria-hidden="true"></i></div>`).join("");
  picker.hidden = false;
  const rect = picker.getBoundingClientRect();
  picker.style.left = `${Math.max(8, Math.min(state.viewport.width - rect.width - 8, position.x + 12))}px`;
  picker.style.top = `${Math.max(8, Math.min(state.viewport.height - rect.height - 8, position.y - rect.height / 2))}px`;
  $("[data-picker-point]", picker)?.focus({ preventScroll:true });
}

function updateHover(position) {
  const hit = hitAt(position);
  if (hit === state.hoveredHit) return;
  state.hoveredHit = hit;
  if (!hit) return hideTooltip();
  const title = hit.point.name;
  const subtitle = `${hit.point.genre} · ${hit.point.region}${hit.point.petSummary ? ` · ${hit.point.petSummary}` : ""}`;
  dom.tooltip.innerHTML = `<strong>${escapeHtml(title)}</strong><small>${escapeHtml(subtitle)}</small>`;
  dom.tooltip.hidden = false;
  const left = Math.min(state.viewport.width - 270, position.x + 13);
  const top = Math.min(state.viewport.height - 60, position.y + 13);
  dom.tooltip.style.left = `${Math.max(8, left)}px`;
  dom.tooltip.style.top = `${Math.max(8, top)}px`;
}

function hideTooltip() { state.hoveredHit = null; dom.tooltip.hidden = true; }

function updateCursorLocation(screen) {
  const mapped = screenToMap(screen.x, screen.y);
  const layer = activeSpatialLayer();
  if (
    mapped.x < SURFACE_MAP_RECT.x || mapped.x > SURFACE_MAP_RECT.x + SURFACE_MAP_RECT.width
    || mapped.y < SURFACE_MAP_RECT.y || mapped.y > SURFACE_MAP_RECT.y + SURFACE_MAP_RECT.height
  ) {
    dom.largeRegion.textContent = state.core.meta.sceneName;
    dom.currentRegion.textContent = "地图边界外";
    dom.coordinate.textContent = "X — · Y —";
    return;
  }
  const world = unprojectMap(mapped.x, mapped.y);
  const insideLayerPatch = layer.id !== "surface" && activePatches().find(patch => {
    const rect = activeLayerMapRect(patch);
    return mapped.x >= rect.x && mapped.x <= rect.x + rect.width && mapped.y >= rect.y && mapped.y <= rect.y + rect.height;
  });
  if (insideLayerPatch) {
    dom.largeRegion.textContent = insideLayerPatch.groupName || layer.groupName;
    dom.currentRegion.textContent = insideLayerPatch.name;
  } else {
    const region = locateRegion(world.x, world.y);
    dom.largeRegion.textContent = region.largeRegion;
    dom.currentRegion.textContent = region.name;
  }
  dom.coordinate.textContent = `X ${Math.round(world.x)} · Y ${Math.round(world.y)}`;
}

function pointInPolygon(x, y, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i, i += 1) {
    const [xi, yi] = polygon[i];
    const [xj, yj] = polygon[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / ((yj - yi) || 1e-12) + xi) inside = !inside;
  }
  return inside;
}

function locateRegion(x, y) {
  const candidates = state.core.regions.filter((region) => {
    const [minX, minY, maxX, maxY] = region.bbox;
    return x >= minX && x <= maxX && y >= minY && y <= maxY && pointInPolygon(x, y, region.polygon);
  }).sort((a, b) => b.priority - a.priority || b.nameScale - a.nameScale || a.polygonArea - b.polygonArea);
  const current = candidates[0];
  const parent = current?.largeRegion || candidates.filter((region) => region.largeRegion).sort((a, b) => a.polygonArea - b.polygonArea)[0]?.largeRegion;
  const mainlandFallback = x < 480000 ? "风眠省" : "洛克里安";
  return {
    largeRegion: parent || (state.core.meta.isMainland ? mainlandFallback : state.core.meta.sceneName),
    name: current?.name || "未命名区域",
  };
}

function scheduleRender() {
  if (state.framePending || !state.core) return;
  state.framePending = true;
  requestAnimationFrame(() => { state.framePending = false; render(); });
}

function render() {
  const ctx = dom.canvas.getContext("2d");
  const { width, height, dpr } = state.viewport;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, width, height);
  ctx.fillStyle = "#e8e1d0";
  ctx.fillRect(0, 0, width, height);
  drawActiveBaseMap(ctx);
  drawUnexploredOverlay(ctx);
  if (state.activeSpatialLayerId !== "surface") {
    drawUndergroundBackdrop(ctx);
    drawActiveLayerPatch(ctx);
  }
  drawPoints(ctx);
  const zoom = Math.round((state.camera.scale / state.camera.fitScale) * 100);
  dom.zoomLabel.textContent = `${zoom}%`;
  $("#zoom-in").disabled = zoom >= 2400;
  $("#zoom-out").disabled = zoom <= 72;
}

function drawActiveBaseMap(ctx) {
  drawTileLayer(ctx, state.tiles, true);
}

function drawUndergroundBackdrop(ctx) {
  drawTileLayer(ctx, state.undergroundTiles, false);
}

function drawActiveLayerPatch(ctx) {
  for (const layer of activePatches()) {
  const mapRect = activeLayerMapRect(layer);
  const topLeft = mapToScreen(mapRect.x, mapRect.y);
  const width = mapRect.width * state.camera.scale;
  const height = mapRect.height * state.camera.scale;
  const image = state.layerImages.get(layer.id);
  if (image) ctx.drawImage(image, topLeft.x, topLeft.y, width, height);
  }
}

function drawTileLayer(ctx, images, drawFallback) {
  const layout = state.core.meta.tileLayout;
  const tileCount = layout.columns * layout.rows;
  for (let index = 0; index < tileCount; index += 1) {
    const row = Math.floor(index / layout.columns);
    const column = index % layout.columns;
    const start = mapToScreen(column * layout.tileSize, row * layout.tileSize);
    const size = layout.tileSize * state.camera.scale;
    if (start.x > state.viewport.width || start.y > state.viewport.height || start.x + size < 0 || start.y + size < 0) continue;
    const image = images[index];
    // Shared device-pixel edges prevent seams without stretching/overlapping tiles.
    const dpr = state.viewport.dpr;
    const x = Math.round(start.x * dpr) / dpr, y = Math.round(start.y * dpr) / dpr;
    const right = Math.round((start.x + size) * dpr) / dpr, bottom = Math.round((start.y + size) * dpr) / dpr;
    if (image) ctx.drawImage(image, x, y, right - x, bottom - y);
    else if (drawFallback) {
      ctx.fillStyle = (row + column) % 2 ? "#e2dac8" : "#e8e1d0";
      ctx.fillRect(start.x, start.y, size, size);
    }
  }
}

function drawUnexploredOverlay(ctx) {
  drawTileLayer(ctx, state.maskTiles, false);
}

function visiblePoints() {
  const topLeft = screenToMap(-50, -50);
  const bottomRight = screenToMap(state.viewport.width + 50, state.viewport.height + 50);
  return state.grid.query(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y).filter((point) =>
    matchesCollection(point) && (state.mapSearch ? state.mapSearch.ids.has(point.id) : state.enabledCategories.has(categoryKey(point))) && point.mx >= topLeft.x && point.mx <= bottomRight.x && point.my >= topLeft.y && point.my <= bottomRight.y
  );
}

function drawPoints(ctx) {
  const points = visiblePoints();
  updateVisibleTotal(points.length);
  state.hits = [];
  for (const point of points) {
    if (point.id !== state.selectedPoint?.id) drawPoint(ctx, point);
  }

  if (state.selectedPoint && pointSelectable(state.selectedPoint)) {
    drawPoint(ctx, state.selectedPoint, true);
  } else dom.focus.hidden = true;
}

function getIcon(url) {
  if (!url) return null;
  if (state.iconCache.has(url)) return state.iconCache.get(url);
  const image = new Image();
  image.decoding = "async";
  image.onload = scheduleRender;
  image.onerror = () => { state.iconCache.set(url, null); scheduleRender(); };
  state.iconCache.set(url, image);
  image.src = assetUrl(url);
  return image;
}

function framedSymbol(point) { return /^\/assets\/ui\/.*\.svg$/.test(point.icon || ""); }

function drawFittedIcon(ctx, url, x, y, size) {
  const image = getIcon(url);
  if (!image?.complete || !image.naturalWidth) return false;
  const factor = size / Math.max(image.naturalWidth, image.naturalHeight);
  const w = image.naturalWidth * factor, h = image.naturalHeight * factor;
  ctx.drawImage(image, x-w/2, y-h/2, w, h);
  return true;
}

function drawMarkerBase(ctx, x, y, size, selected = false) {
  ctx.save(); ctx.shadowColor = "#33291f40"; ctx.shadowBlur = 3; ctx.shadowOffsetY = 1;
  drawFittedIcon(ctx, selected ? "/map-media/3361522b305b61200f90.png" : "/map-media/aaf12989606c6dc7593c.png", x, y, size);
  ctx.restore();
}

function getMarkerImage(point, selected) {
  const { portrait, size } = markerStyle(point, selected);
  const boss = portrait && point.classId === 3;
  const frame = (portrait && point.iconKind !== "npc") || framedSymbol(point);
  const dpr = state.viewport.dpr;
  const key = `${point.icon}|${size}|${boss}|${frame}|${selected}|${dpr}`;
  if (state.markerCache.has(key)) return state.markerCache.get(key);
  const icon = getIcon(point.icon);
  if (!icon?.complete || !icon.naturalWidth) return null;
  if (frame) {
    const base = getIcon((boss ? "/map-media/3361522b305b61200f90.png" : "/map-media/aaf12989606c6dc7593c.png"));
    if (!base?.complete || !base.naturalWidth) return null;
  }
  const extent = size + 24;
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = Math.ceil(extent * dpr);
  const ctx = canvas.getContext("2d");
  ctx.scale(dpr, dpr);
  ctx.imageSmoothingQuality = "high";
  const center = extent / 2;
  // The game places a 95px head over a 69px frame; ears extend outside it.
  if (boss) drawMarkerBase(ctx, center + size * 2 / 95, center + size / 95, size * 69 / 95, true);
  else if (frame) drawMarkerBase(ctx, center, center, size);
  drawFittedIcon(ctx, point.icon, center, center, boss ? size : frame ? size * .76 : size);
  const cached = { canvas, extent: canvas.width / dpr };
  state.markerCache.set(key, cached);
  return cached;
}

function drawPoint(ctx, point, selected = false) {
  const screen = mapToScreen(point.mx, point.my);
  const { size } = markerStyle(point, selected);
  const centerY = screen.y - size / 2 + 5;
  if (selected) updateFocusCursor(point, screen.x, centerY, size);
  const marker = getMarkerImage(point, selected);
  const completed = collectedPoint(point);
  ctx.save();
  if (completed && !selected) ctx.globalAlpha = .45;
  if (marker) {
    const dpr = state.viewport.dpr;
    const x = Math.round((screen.x - marker.extent / 2) * dpr) / dpr;
    const y = Math.round((centerY - marker.extent / 2) * dpr) / dpr;
    // One device pixel per cached pixel: fractional placement blurs the icon twice.
    ctx.drawImage(marker.canvas, x, y, marker.extent, marker.extent);
  } else {
    ctx.beginPath(); ctx.arc(screen.x, centerY, 5, 0, Math.PI * 2);
    ctx.fillStyle = CLASS_COLORS[point.classId] || "#9ab7ac"; ctx.fill();
  }
  ctx.restore();
  if (completed) {
    const x = screen.x + size*.32, y = centerY + size*.3;
    ctx.save(); ctx.beginPath(); ctx.arc(x,y,7.5,0,Math.PI*2); ctx.fillStyle = '#fffdf6'; ctx.fill();
    ctx.font = '900 13px "Font Awesome 6 Free"'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#6c633f'; ctx.fillText('\uf058',x,y+.5); ctx.restore();
  }
  state.hits.push({ type:"point", point, x:screen.x, y:centerY, radius:Math.max(18,size/2+3) });
}

function updateFocusCursor(point, x, y, size) {
  // One decorative overlay follows the canvas projection. Its entry animation
  // does not redraw the map or change marker hit areas.
  if (dom.focus.dataset.point !== point.id || dom.focus.hidden) {
    dom.focus.innerHTML = '<div class="map-focus-part is-top"></div><div class="map-focus-part is-bottom"></div><div class="map-focus-part is-left"></div><div class="map-focus-part is-right"></div>';
    dom.focus.dataset.point = point.id;
  }
  dom.focus.style.transform = `translate(${x}px, ${y}px) scale(${Math.max(.54, size / 72)})`;
  dom.focus.hidden = false;
}

function focusPoint(point, fromSearch = false, query = "") {
  if (!point) return;
  const pets = state.core.details[point.id]?.habitat?.pets || [];
  state.habitatQuery = habitatQuery(pets, query || state.mapSearch?.query || "");
  if (state.mapSearch && (!state.mapSearch.ids.has(point.id) || (query && query.trim() !== state.mapSearch.query))) clearMapSearch();
  closeSearch();
  if (root.clientWidth <= 760) closeLayers();
  if (fromSearch && !state.mapSearch) {
    state.enabledCategories.add(categoryKey(point));
    $$(".category-check", dom.filters).forEach(input => { input.checked = state.enabledCategories.has(input.dataset.category); });
    updateClassCheckboxes(); savePreferences();
  }
  renderPointDetails(point, fromSearch);
}

function focusPointAcrossLayers(point, fromSearch = false, query = "", navigate = fromSearch) {
  if (!point) return;
  // Map clicks inspect the current view. Only a search result or the detail's
  // explicit floor link requests navigation to the point's underground map.
  if (!navigate) {
    if (pointSelectable(point)) focusPoint(point, fromSearch, query);
    return;
  }
  const floor = floorForPoint(point, state.activeSpatialLayerId, state.spatialLayerById);
  const patch = (point.mapLayerIds || [point.mapLayerId]).find(id => {
    const layer = state.spatialLayerById.get(id);
    return layer?.kind === "underground" && (!patchFloor(layer) || patchFloor(layer) === floor);
  }) || null;
  const changedPatch = state.focusedPatchId !== patch;
  state.focusedPatchId = patch || null;
  // Layer/filter state switches synchronously. Open the new details immediately;
  // downloading its pictures must not delay a click or reopen an older result.
  if (floor !== state.activeSpatialLayerId || changedPatch) setSpatialLayer(floor);
  if (!pointInActiveSpatialLayer(point)) return;
  focusPoint(point, fromSearch, query);
}

function detailIcon(point) {
  const portrait = markerStyle(point).portrait;
  return point.icon ? `<img class="${point.iconKind === "npc" ? "npc-icon" : portrait && point.classId === 3 ? "boss-icon" : portrait ? "portrait-icon" : framedSymbol(point) ? "symbol-icon" : "pin-icon"}" src="${escapeHtml(point.icon)}" alt="" />` : `<span>${escapeHtml(point.genre.slice(0, 1))}</span>`;
}

function renderPointDetails(point, fromSearch = false) {
  pointComments.close();
  state.selectedPoint = point;
  const detail = state.core.details[point.id] || {};
  const spatialLayer = state.spatialLayerById.get(point.mapLayerId);
  const targetFloor = floorForPoint(point, state.activeSpatialLayerId, state.spatialLayerById);
  const floorLink = targetFloor !== state.activeSpatialLayerId
    ? `<div class="detail-floor-link" data-nrc-tag="button" role="button" tabindex="0" data-detail-floor="${escapeHtml(point.id)}"><i class="fa-solid fa-layer-group" aria-hidden="true"></i>查看${escapeHtml(patchFloor(spatialLayer) ? FLOOR_LABELS[targetFloor] : "地下地图")}<i class="fa-solid fa-arrow-right" aria-hidden="true"></i></div>` : "";
  let sections = "";
  if (detail.owlSanctuary) sections += renderOwlSection(detail.owlSanctuary);
  if (detail.shops) sections += renderShopSection(detail.shops);
  if (detail.dungeon) sections += renderDungeonSection(detail.dungeon);
  if (detail.habitat) sections += renderHabitatSection(detail.habitat);
  if (detail.fruitTree) sections += renderFruitTreeSection(detail.fruitTree);
  if (detail.quiz) sections += renderQuizSection(detail.quiz);
  if (detail.forceTester) sections += renderForceTesterSection(detail.forceTester);
  if (detail.music) sections += renderMusicSection(detail.music);
  if (detail.lottery) sections += renderLotterySection(detail.lottery);
  if (detail.opponentMagic) sections += `<div class="detail-section">${renderOpponentMagic(detail.opponentMagic)}</div>`;
  if (detail.rewardSections) sections += renderRewardSections(detail.rewardSections);
  dom.details.classList.toggle("is-habitat", Boolean(detail.habitat));
  dom.detailContent.innerHTML = `<div class="detail-hero"><div class="detail-icon">${detailIcon(point)}</div><span class="detail-type">${escapeHtml(point.genre)}</span>
    <div data-nrc-tag=h1>${escapeHtml(detail.title || point.name)}</div><div class="detail-location">${escapeHtml(point.largeRegion)} <i class="fa-solid fa-chevron-right" aria-hidden="true"></i> ${escapeHtml(point.region)} · ${escapeHtml(spatialLayer?.id === "surface" ? "地表" : spatialLayer?.name || "地表")}</div>${floorLink}</div>
    <div class="detail-body">${detail.description && !detail.habitat ? `<p class="detail-description">${textHtml(detail.description)}</p>` : ""}${renderCollectionControl(point)}<div class="detail-comments-link" data-nrc-tag="button" role="button" tabindex="0"><i class="fa-solid fa-comments" aria-hidden="true"></i>点位评论<i class="fa-solid fa-chevron-down" aria-hidden="true"></i></div>${point.estimatedRegion ? '<p class="data-note">区域归属为推定结果，请结合游戏内位置确认。</p>' : ""}${sections}<div class="detail-section map-point-comments"></div></div>`;
  const commentsHost = $(".map-point-comments", dom.detailContent);
  $(".detail-comments-link", dom.detailContent).addEventListener("click", () => commentsHost.scrollIntoView({behavior:"smooth", block:"start"}));
  pointComments.show(commentsHost, point);
  updateCollectionUI();
  dom.largeRegion.textContent = point.largeRegion;
  dom.currentRegion.textContent = point.region;
  openDetails(); scheduleRender();
  const scale = fromSearch ? Math.max(state.camera.scale, state.camera.fitScale * 5) : state.camera.scale;
  const mobile = root.clientWidth <= 760;
  const offsetX = mobile ? 0 : (dom.details.getBoundingClientRect().width + 24) / 2;
  const offsetY = mobile ? dom.details.getBoundingClientRect().height / 2 : 0;
  animateCamera({ x:point.mx + offsetX / scale, y:point.my + offsetY / scale, scale });
}

function renderItem(item, quantity = null, note = "") {
  if (!item) return "";
  return `<div class="item-row">${item.icon ? `<img src="${escapeHtml(item.icon)}" alt="" />` : ""}<div><strong>${escapeHtml(item.name || "名称待确认")}</strong>
    <small>${escapeHtml(note || item.description || "")}</small></div>${quantity !== null && quantity !== undefined ? `<span class="quantity">× ${escapeHtml(quantity)}</span>` : ""}</div>`;
}

function renderFruitTreeSection(tree) {
  const requirement = tree.unlockRequirement;
  return `<div class="detail-section fruit-tree-section">
    <div class="fruit-tree-unlock"><i class="fa-solid fa-book-open" aria-hidden="true"></i><div>
      <div class="map-detail-label">解锁条件</div>
      ${requirement ? `<div class="fruit-tree-book">${escapeHtml(requirement.name)}</div><div>记录 <span class="fruit-tree-total">${escapeHtml(requirement.count)}</span> 只精灵</div>` : '<div class="fruit-tree-pending">待确认</div>'}
    </div></div><div class="fruit-tree-heading">树苗的果实</div>
    ${(tree.rewards || []).map(reward => `<div class="fruit-tree-reward">
      <div class="fruit-tree-item">${reward.item.icon ? `<img src="${escapeHtml(reward.item.icon)}" alt="" />` : ""}<div><div class="fruit-tree-name">${escapeHtml(reward.item.name)}</div><div class="fruit-tree-count">× ${escapeHtml(reward.count)}</div></div></div>
      <div class="fruit-tree-hint">放入眠枭庇护所，可吸引</div>
      <div class="fruit-tree-pets">${(reward.pets || []).map(pet => `<div class="fruit-tree-pet">${pet.icon ? `<img src="${escapeHtml(pet.icon)}" alt="" loading="lazy" />` : ""}<div>${escapeHtml(pet.name)}</div></div>`).join("")}</div>
    </div>`).join("")}</div>`;
}

function renderQuizSection(quiz) {
  const pets = quiz.pets || [];
  return `<div class="detail-section map-quiz">
    <div class="map-quiz-question"><div class="map-detail-label"><i class="fa-solid fa-circle-question" aria-hidden="true"></i>${quiz.answer ? '问题' : '精灵线索'}</div><div>${escapeHtml(quiz.question)}</div></div>
    <div class="map-quiz-answer"><div class="map-detail-label"><i class="fa-solid fa-check" aria-hidden="true"></i>${quiz.answer ? '正确答案' : '展示精灵'}</div>
      ${quiz.answer ? `<div class="map-quiz-answer-text">${escapeHtml(quiz.answer)}</div>` : `<div class="map-quiz-pets">${pets.map(pet => `<div class="map-quiz-pet">${pet.icon ? `<img src="${escapeHtml(pet.icon)}" alt="" loading="lazy" />` : ''}<div><div class="map-quiz-answer-text">${escapeHtml(pet.name)}</div>${pet.form && pet.form !== '本来的样子' ? `<div class="map-quiz-form">${escapeHtml(pet.form)}</div>` : ''}</div></div>`).join('')}</div>${pets.length > 1 ? '<div class="map-quiz-hint">展示其中任意一只即可</div>' : ''}`}
    </div></div>`;
}

function renderForceTesterSection(tester) {
  return `<div class="detail-section force-tester-section">
    <div class="force-tester-requirement"><i class="fa-solid fa-weight-hanging" aria-hidden="true"></i><div><div class="map-detail-label">精灵体重总和</div><div class="force-tester-weight">${escapeHtml(tester.requirement)}</div></div></div>
    <div class="map-detail-heading">可用精灵</div><div class="force-tester-hint">以下任选一只，即可单独满足要求</div>
    <div class="force-tester-pets">${tester.pets.map(pet => `<div class="force-tester-pet" title="${escapeHtml(pet.name)} · ${escapeHtml(pet.weightMin)}–${escapeHtml(pet.weightMax)} 千克"><img src="${escapeHtml(pet.icon)}" alt="${escapeHtml(pet.name)}" loading="lazy" width="56" height="56" /><div>${escapeHtml(pet.name)}</div></div>`).join('')}</div>
  </div>`;
}

function renderMusicSection(music) {
  return `<div class="detail-section map-music"><div class="map-detail-heading">可收录曲目</div>
    ${(music.tracks || []).map(track => `<div class="map-music-track"><i class="fa-solid fa-music" aria-hidden="true"></i><div><div class="map-music-name">${escapeHtml(track.name)}</div>${track.type ? `<div class="map-music-type">${escapeHtml(track.type)}</div>` : ''}</div></div>`).join('')}</div>`;
}

function detailMore(count) {
  return `<div class="detail-more" data-nrc-tag="button" role="button" tabindex="0" data-detail-more="${count}" aria-expanded="false">展开全部 ${count} 项 <i class="fa-solid fa-chevron-down" aria-hidden="true"></i></div>`;
}

function rewardGrid(entries) {
  return `<div class="detail-expandable"><div class="map-reward-grid">${entries.map(entry => `<div class="map-reward-item">
    ${entry.item.icon ? `<img src="${escapeHtml(entry.item.icon)}" alt="" loading="lazy" />` : `<i class="fa-solid fa-${entry.item.type === "称号" ? "tag" : "gift"} map-reward-symbol" aria-hidden="true"></i>`}
    <div class="map-reward-copy"><div class="map-reward-name">${escapeHtml(entry.item.name)}</div>${entry.item.type === "称号" ? '<div class="map-reward-kind">名片称号</div>' : ""}${entry.count != null ? `<div class="map-reward-count">× ${escapeHtml(entry.count)}</div>` : ""}</div>
  </div>`).join("")}</div>${entries.length > 8 ? detailMore(entries.length) : ""}</div>`;
}

function renderRewardSections(sections) {
  return `<div class="map-reward-sections">${sections.map(section => {
    const fixed = (section.rewards || []).filter(entry => !entry.possible);
    const random = (section.rewards || []).filter(entry => entry.possible);
    const party = section.pets || [];
    return `<div class="detail-section map-reward-section"><div class="map-detail-heading">${escapeHtml(party.length ? section.title.replace(/奖励$/, "") : section.title)}</div>
      ${section.opponentMagic ? renderOpponentMagic(section.opponentMagic) : ''}
      ${section.note ? `<div class="map-reward-note">${escapeHtml(section.note)}</div>` : ""}
      ${party.length ? `<div class="map-battle-party" role="group" aria-label="对战阵容">${party.map(pet => `<div class="map-battle-pet"><img src="${escapeHtml(pet.icon)}" alt="${escapeHtml(pet.name)}" loading="lazy" width="48" height="48" /></div>`).join("")}</div><div class="map-reward-subheading">奖励</div>` : ""}
      ${fixed.length ? rewardGrid(fixed) : ""}${random.length ? `<div class="map-reward-subheading">可能掉落</div>${rewardGrid(random)}` : ""}</div>`;
  }).join("")}</div>`;
}

function renderLotterySection(lottery) {
  return `<div class="detail-section map-lottery"><div class="map-detail-heading">抽屉奖励</div>
    <div class="map-lottery-drawers">${lottery.drawers.map(drawer => {
      const fixed=drawer.rewards.filter(entry=>!entry.possible), random=drawer.rewards.filter(entry=>entry.possible);
      return `<div class="map-lottery-drawer"><div class="map-lottery-label">${escapeHtml(drawer.name)}</div>${fixed.length ? rewardGrid(fixed) : ''}${random.length ? `<div class="map-lottery-random">随机获得</div>${rewardGrid(random)}` : ''}</div>`;
    }).join('')}</div>
    ${lottery.completionRewards?.length ? `<div class="map-lottery-completion"><div class="map-detail-heading"><i class="fa-solid fa-gift" aria-hidden="true"></i>全部领完后的额外奖励</div>${rewardGrid(lottery.completionRewards)}</div>` : ''}</div>`;
}

function renderOpponentMagic(magic) {
  return `<div class="map-opponent-magic"><i class="fa-solid fa-wand-magic-sparkles" aria-hidden="true"></i><div>对手魔力</div><div class="map-opponent-magic-value">${escapeHtml(magic.count)}</div></div>`;
}

function renderPicnicItems(items) {
  const groups = ["食物", "天气", "心情"].filter(group => items.some(row => row.group === group));
  return `<div class="detail-section picnic-section"><div class="map-detail-heading">招待道具效果</div>
    <div class="picnic-tabs">${groups.map((group, index) => `<div data-nrc-tag="button" role="button" tabindex="0" data-picnic-tab="${group}" aria-pressed="${index === 0}">${group}<span>${items.filter(row => row.group === group).length}</span></div>`).join("")}</div>
    ${groups.map((group, index) => {
      const rows = items.filter(row => row.group === group);
      return `<div data-picnic-panel="${group}" class="detail-expandable"${index ? " hidden" : ""}><div class="picnic-items">${rows.map(row => `<div class="picnic-item">${row.item.icon ? `<img src="${escapeHtml(row.item.icon)}" alt="" loading="lazy" />` : ""}<div><div class="picnic-item-name">${escapeHtml(row.item.name)}</div><div class="picnic-item-effect">${escapeHtml(row.description.replace(/^生效时，/, ""))}</div></div></div>`).join("")}</div>${rows.length > 6 ? detailMore(rows.length) : ""}</div>`;
    }).join("")}</div>`;
}

function renderHabitatCards(habitat, query) {
  const pets = filterHabitatPets(habitat.pets || [], query);
  return pets.map(pet => {
    const name = pet.name + (pet.form && pet.form !== '本来的样子' ? `（${pet.form}）` : '');
    return `<div class="habitat-pet-card" title="${escapeHtml(name)}">${pet.icon ? `<img src="${escapeHtml(pet.icon)}" alt="${escapeHtml(name)}" loading="lazy" width="56" height="56" />` : ''}</div>`;
  }).join("") || '<div class="habitat-no-results">没有找到这只精灵，试试名称或系别。</div>';
}

function updateHabitatPets(query) {
  const habitat = state.core.details[state.selectedPoint?.id]?.habitat;
  if (!habitat) return;
  state.habitatQuery = query;
  $("#habitat-pets").innerHTML = renderHabitatCards(habitat, query);
  $("#habitat-result-count").textContent = `${filterHabitatPets(habitat.pets, query).length} / ${habitat.pets.length} 种`;
  $("[data-habitat-clear]").hidden = !query.trim();
}

function renderHabitatSection(habitat) {
  const query = state.habitatQuery;
  const count = filterHabitatPets(habitat.pets || [], query).length;
  return `<div data-nrc-tag=section class="detail-section habitat-results"><div class="habitat-results-heading"><div data-nrc-tag=h3>出没精灵</div><span id="habitat-result-count" role="status">${count} / ${habitat.pets.length} 种</span></div>
    <div class="habitat-filter"><div data-nrc-tag=label><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i><input id="habitat-search" type="search" value="${escapeHtml(query)}" placeholder="精灵名称 / 系别" aria-label="查找本区域的精灵" /></div><div data-nrc-tag=button data-nrc-type="button" data-habitat-clear${query ? "" : " hidden"}>查看全部</div></div>
    <div class="habitat-location-note"><i class="fa-solid fa-location-dot" aria-hidden="true"></i> 区域代表点，非精确刷新位置</div>
    <div class="habitat-pet-grid" id="habitat-pets">${renderHabitatCards(habitat, query)}</div></div>
    <div data-nrc-tag=details class="habitat-region-summary"><div data-nrc-tag=summary>栖息地信息 <i class="fa-solid fa-chevron-down" aria-hidden="true"></i></div><div class="info-grid"><div class="info-card"><small>所属区域</small><strong>${escapeHtml(habitat.belongCampName || "—")}</strong></div><div class="info-card"><small>常见系别</small><strong>${escapeHtml((habitat.commonTypes || []).map(t => t.name).join(" / ") || "—")}</strong></div></div></div>`;
}

function renderOwlSection(owl) {
  const unlock = owl.unlock || {};
  const upgrade = owl.upgrade;
  const levels = upgrade ? upgrade.levels.map((level) => {
    const effects = (level.effects || []).map((effect) => `<p>${textHtml(effect)}</p>`).join("");
    const next = level.nextUpgrade
      ? `<div class="level-upgrade"><strong>升至 Lv.${escapeHtml(level.level + 1)}</strong><small>所需材料</small>
          <div class="upgrade-materials">${level.nextUpgrade.materials.map((material) => renderItem(material.item, material.count, material.item.description)).join("")}</div></div>`
      : `<div class="level-max">已达到当前最高等级</div>`;
    return `<div class="level-card"><span class="level-number">Lv.${escapeHtml(level.level)}</span><div class="level-effects">${effects || "<p>当前等级无额外效果</p>"}</div>${next}</div>`;
  }).join("") : "";
  const duration = upgrade?.durationMultiplier
    ? `Lv.3 的招待道具持续时间为基础值的 ${Math.round(upgrade.durationMultiplier * 100)}%（+${Math.round((upgrade.durationMultiplier - 1) * 100)}%）。`
    : "";
  return `<div data-nrc-tag=section class="detail-section"><div data-nrc-tag=h3>${escapeHtml(owl.type)}眠枭庇护所</div>
    <div class="owl-name">${escapeHtml(owl.name)}</div>
    ${unlock.item ? `<div class="owl-unlock"><div class="map-detail-label">${unlock.note ? "滋养说明" : unlock.item.colorName === "紫色" ? '解锁需求（Lv.0 <i class="fa-solid fa-arrow-right" aria-hidden="true"></i> Lv.1）' : "所需星星"}</div>${renderItem({...unlock.item, name:(unlock.item.colorName || "") + unlock.item.name}, unlock.count, unlock.note)}</div>` : ""}
    ${owl.picnicItems?.length ? renderPicnicItems(owl.picnicItems) : ""}
    ${owl.specialFruits?.length ? renderSanctuaryFruits(owl.specialFruits) : ""}
    ${upgrade ? `<div class="upgrade-heading"><strong>庇护所升级</strong><small>Lv.1–Lv.${escapeHtml(upgrade.maxLevel)}</small></div>${levels}
      <div class="data-note">${escapeHtml(duration)}</div>`
      : ""}</div>`;
}

function renderSanctuaryFruits(fruits) {
  return `<div class="sanctuary-fruits"><div class="map-detail-heading">可吸引的特殊形态</div>
    <div class="sanctuary-fruits-note">在这座庇护所放入以下果实，可吸引对应形态的精灵。</div>
    <div class="detail-expandable"><div class="sanctuary-fruit-list">${fruits.map(row => `<div class="sanctuary-fruit">
      <div class="fruit-tree-item">${row.item.icon ? `<img src="${escapeHtml(row.item.icon)}" alt="" loading="lazy" />` : ""}<div class="fruit-tree-name">${escapeHtml(row.item.name)}</div></div>
      <div class="sanctuary-fruit-pets">${row.pets.map(pet => `<div class="sanctuary-fruit-pet">${pet.icon ? `<img src="${escapeHtml(pet.icon)}" alt="" loading="lazy" />` : ""}<div><div>${escapeHtml(pet.name)}</div>${pet.form ? `<div class="sanctuary-fruit-form">${escapeHtml(pet.form)}</div>` : ""}</div></div>`).join("")}</div>
    </div>`).join("")}</div>${fruits.length > 4 ? detailMore(fruits.length) : ""}</div></div>`;
}

function renderShopSection(shops) {
  return shops.map((shop) => `<div data-nrc-tag=section class="detail-section"><div data-nrc-tag=h3>${escapeHtml(shop.name)} <small>${escapeHtml(shop.location || "商店")}</small></div>
    ${shop.stock.length ? shop.stock.map((goods) => {
      const price = goods.price?.amount != null ? `价格 ${goods.price.amount}` : "";
      const limit = goods.limit ? `限购 ${goods.limit}` : "";
      return renderItem(goods.item || { name: goods.name }, goods.quantity, [price, limit].filter(Boolean).join(" · "));
    }).join("") : `<p class="detail-description">商品请以游戏内商店为准。</p>`}</div>`).join("");
}

function renderDungeonSection(dungeon) {
  if (dungeon.periods?.length) {
    return `<div class="timed-dungeon detail-section"><div class="map-detail-heading">进入时分</div>
      <div class="dungeon-period-tabs" role="group" aria-label="选择守护地时分">${dungeon.periods.map((room, index) => `<div role="button" tabindex="0" data-dungeon-period="${index}" aria-pressed="${index === 0}">${escapeHtml(room.subtitle)}</div>`).join('')}</div>
      ${dungeon.periods.map((room, index) => `<div data-dungeon-room="${index}"${index ? ' hidden' : ''}>${renderDungeonSection({...room, periodOnly:true})}</div>`).join('')}</div>`;
  }
  const rewards = (dungeon.rewards || []).map((reward) => reward.item
    ? renderItem(reward.item, reward.count, reward.item.description)
    : `<div class="item-row"><div><strong>其他奖励</strong><small>具体内容以游戏内展示为准</small></div>${reward.count ? `<span class="quantity">× ${escapeHtml(reward.count)}</span>` : ""}</div>`).join("");
  const eggs = (dungeon.specialEggs || []).map((egg) => `<div class="egg-card"><div class="egg-head">${egg.item?.icon ? `<img src="${escapeHtml(egg.item.icon)}" alt="" />` : ""}<div><strong>${escapeHtml(egg.petName || egg.item?.name || "特殊精灵蛋")}</strong><small>固定性格：${escapeHtml((egg.fixedNatures || []).join(" / ") || "—")}</small></div></div>
    <div class="stat-chips">${(egg.fixedStats || []).map((stat) => `<span>${escapeHtml(stat.name)} ${escapeHtml(stat.value)}</span>`).join("")}</div>
    ${egg.fixedTalent ? `<p class="data-note">固定特长：${escapeHtml(egg.fixedTalent.name || "待确认")}${egg.fixedTalent.description ? ` · ${escapeHtml(egg.fixedTalent.description)}` : ""}</p>` : ""}</div>`).join("");
  return `${dungeon.periodOnly ? '' : `<div data-nrc-tag=section class="detail-section"><div data-nrc-tag=h3>秘境信息 <small>${escapeHtml(dungeon.subtitle)}</small></div>
    <div class="info-card"><small>秘境</small><strong>${escapeHtml(dungeon.name)}</strong></div>
    ${dungeon.description ? `<p class="detail-description" style="margin-top:12px">${textHtml(dungeon.description)}</p>` : ""}</div>`}
    <div data-nrc-tag=section class="detail-section"><div data-nrc-tag=h3>秘境奖励 <small>${dungeon.rewards?.length || 0} 项</small></div>${rewards || `<p class="detail-description">奖励请以游戏内展示为准。</p>`}${eggs ? `<div data-nrc-tag=h3 style="margin-top:18px">特殊精灵蛋</div>${eggs}` : ""}</div>`;
}

function renderQualityDetails() {
  dom.details.classList.remove("is-habitat");
  state.selectedPoint = null;
  dom.detailContent.innerHTML = `<div class="detail-hero"><div class="detail-icon"><i class="ui-icon fa-solid fa-compass" aria-hidden="true"></i></div><span class="detail-type">探索指南</span><div data-nrc-tag=h1>地图指南</div></div><div class="detail-body">
    <div data-nrc-tag=section class="detail-section"><div data-nrc-tag=h3>从这里开始</div><p class="detail-description">先选探索、精灵、宝箱等快捷筛选，再勾选具体类型。顶部搜索覆盖所有类型和楼层，选择结果会自动进入对应楼层并定位。</p><p class="detail-description">大地图包含地表与地底点位。点选时保留当前视图；查看地下点位详情后，可使用楼层入口进入对应地下地图。地图上的楼层按钮也能随时切换。</p><p class="detail-description">拖动地图探索，滚轮或双指缩放。点位重叠时，点击后可从列表中选择。键盘可用 / 搜索，方向键移动地图，+ / − 缩放，0 回到全图。</p><p class="detail-description">右侧「标准 / 高清」可切换地图画质，选择会保存在本机。高清原图细节更完整，首次加载需要更多流量。</p><p class="data-note">精灵栖息地点代表区域，不是精确刷新位置。动态内容请以游戏内为准。</p></div></div>`;
  openDetails();
  scheduleRender();
}

initialize();

  }
  function scan() {
    document.querySelectorAll(".nrc-world-map").forEach(mount);
  }
  window.NrcWorldMap = {receive:(title, value) => {
    if (allowedPages.has(title) && !decoded.has(title)) payloads.set(title, value);
  }, scan};
  /* BWIKI div 控件：键盘操作、禁用、标签关联与折叠行为。 */
(function () {
    'use strict';
    if (window.NrcDivUI) return;
    const converted = new Set(['button','article','section','header','footer','nav','main','aside','figure','figcaption','label','details','summary','h1','h2','h3','h4','h5','h6','ul','ol','li']);
    const prepared = new WeakSet();
    const hiddenBeforeFold = new WeakMap();
    const kind = node => node.getAttribute('data-nrc-tag');
    let labelId = 0;
    function linkLabel(node) {
        const input = node.getAttribute('data-nrc-for') ? document.getElementById(node.getAttribute('data-nrc-for')) : node.querySelector('input,select,textarea');
        if (!input || input.hasAttribute('aria-label') || input.hasAttribute('aria-labelledby')) return;
        if (!node.id) node.id = 'nrc-div-label-' + (++labelId);
        input.setAttribute('aria-labelledby',node.id);
    }
    function syncDetails(node) {
        const open = node.hasAttribute('data-nrc-open');
        Array.from(node.children).forEach(child => {
            if (kind(child) === 'summary') {
                child.setAttribute('aria-expanded', String(open));
            } else {
                if (!hiddenBeforeFold.has(child)) hiddenBeforeFold.set(child, child.hidden);
                child.hidden = !open || hiddenBeforeFold.get(child);
                child.toggleAttribute("data-nrc-folded", !open);
            }
        });
    }
    function prepare(node) {
        if (!node || node.nodeType !== 1 || !node.hasAttribute('data-nrc-tag')) return node;
        const tag = kind(node);
        if (prepared.has(node)) { if (tag === 'details') syncDetails(node); if (tag === 'label') linkLabel(node); return node; }
        prepared.add(node);
        if (['ul','ol','li'].includes(tag) && !node.hasAttribute('role')) node.setAttribute('role', tag === 'li' ? 'listitem' : 'list');
        if (/^h[1-6]$/.test(tag)) { node.setAttribute('role','heading'); node.setAttribute('aria-level',tag.slice(1)); }
        if (tag === 'button' || tag === 'summary') {
            if (!node.hasAttribute('role')) node.setAttribute('role','button');
            if (!node.hasAttribute('tabindex')) node.tabIndex = 0;
        }
        if (tag === 'button') {
            Object.defineProperty(node,'type',{configurable:true,get(){return node.getAttribute('data-nrc-type') || 'button';},set(value){node.setAttribute('data-nrc-type',value);}});
            let disabled = node.disabled === true || node.hasAttribute('disabled') || node.getAttribute('aria-disabled') === 'true';
            const enabledTabIndex = node.getAttribute('tabindex');
            Object.defineProperty(node, 'disabled', {configurable:true, get() { return node.getAttribute('aria-disabled') === 'true' || node.hasAttribute('disabled'); }, set(value) {
                node.setAttribute('aria-disabled',String(Boolean(value)));
                node.toggleAttribute('disabled',Boolean(value));
                node.setAttribute('tabindex',value ? '-1' : enabledTabIndex);
            }});
            node.disabled = disabled;
        }
        if (tag === 'label') {
            linkLabel(node);
            Object.defineProperty(node,'htmlFor',{configurable:true,get(){return node.getAttribute('data-nrc-for') || '';},set(value){node.setAttribute('data-nrc-for',value);}});
        }
        if (tag === 'details') {
            Object.defineProperty(node,'open',{configurable:true,get(){return node.hasAttribute('data-nrc-open');},set(value){
                const changed = Boolean(value) !== node.hasAttribute('data-nrc-open');
                node.toggleAttribute('data-nrc-open', Boolean(value)); syncDetails(node);
                if (changed) node.dispatchEvent(new Event('toggle'));
            }});
            syncDetails(node);
        }
        return node;
    }
    function scan(root) {
        prepare(root);
        if (root.querySelectorAll) root.querySelectorAll('[data-nrc-tag]').forEach(prepare);
    }
    function create(tag) {
        if (!converted.has(tag)) return document.createElement(tag);
        const node = document.createElement('div');
        node.setAttribute('data-nrc-tag',tag);
        if (/^h[1-6]$/.test(tag)) { node.setAttribute('role','heading'); node.setAttribute('aria-level',tag.slice(1)); }
        return prepare(node);
    }
    document.addEventListener('click', event => {
        const button = event.target.closest && event.target.closest('[data-nrc-tag=button]');
        if (button && (button.disabled || button.getAttribute('aria-disabled') === 'true')) {
            event.preventDefault(); event.stopImmediatePropagation();
        }
    }, true);
    document.addEventListener('keydown', event => {
        if (event.defaultPrevented || event.repeat || !['Enter',' '].includes(event.key)) return;
        const control = event.target.closest && event.target.closest('[data-nrc-tag=button],[data-nrc-tag=summary]');
        if (!control || event.target !== control) return;
        event.preventDefault();
        if (!control.disabled && control.getAttribute('aria-disabled') !== 'true') control.click();
    });
    document.addEventListener('click', event => {
        if (event.defaultPrevented || !event.target.closest) return;
        const summary = event.target.closest('[data-nrc-tag=summary]');
        if (summary && !event.target.closest('a,input,select,textarea,[data-nrc-tag=button]')) {
            const details = summary.closest('[data-nrc-tag=details]');
            if (details) { prepare(details); details.open = !details.open; }
            return;
        }
        const label = event.target.closest('[data-nrc-tag=label]');
        if (label && !event.target.closest('a,input,select,textarea,[data-nrc-tag=button]')) {
            const input = label.getAttribute('data-nrc-for') ? document.getElementById(label.getAttribute('data-nrc-for')) : label.querySelector('input,select,textarea');
            if (input && !input.disabled) { input.focus(); if (input.matches('input[type=checkbox],input[type=radio]')) input.click(); }
        }
        const button = event.target.closest('[data-nrc-tag=button][data-nrc-type=submit]');
        if (button) { const form = button.closest('form'); if (form) form.requestSubmit(); }
    });
    window.NrcDivUI = {create, scan};
    scan(document);
    new MutationObserver(records => records.forEach(record => {
        if (record.type === 'childList') {
            record.addedNodes.forEach(scan);
            if (record.target.nodeType === 1) {
                if (kind(record.target) === 'details') syncDetails(record.target);
                const label = record.target.closest('[data-nrc-tag=label]');
                if (label) linkLabel(label);
            }
        } else if (kind(record.target) === 'details') syncDetails(record.target);
    })).observe(document.documentElement, {childList:true,subtree:true,attributes:true,attributeFilter:['data-nrc-open']});
}());

/* 评论表情：固定短码、可信图片映射与输入控件。 */
(function () {
    'use strict';
    if (window.NrcFlowThreadEmojis) return;
    const catalog = [
        // BEGIN EMOJI CATALOG
        {"token": "[捕捉精灵]", "name": "捕捉精灵", "file": "ChatEmoji_19.png", "url": "https://patchwiki.biligame.com/images/nrc/d/dd/s1937prj8tvcrl0peu3r6h1o5tbxsbp.png"},
        {"token": "[刷洛克贝]", "name": "刷洛克贝", "file": "ChatEmoji_17.png", "url": "https://patchwiki.biligame.com/images/nrc/a/a5/858uxhdxpt4xtkvdjvyhf87obouivjt.png"},
        {"token": "[刷采集物]", "name": "刷采集物", "file": "ChatEmoji_18.png", "url": "https://patchwiki.biligame.com/images/nrc/4/4a/sxt0x2pc6ci2x21obudl6zll81tjpdj.png"},
        {"token": "[吃]", "name": "吃", "file": "ChatEmoji_1.png", "url": "https://patchwiki.biligame.com/images/nrc/a/a5/3sxa35q7v3869edxy59840djpob4ho1.png"},
        {"token": "[爱你]", "name": "爱你", "file": "ChatEmoji_2.png", "url": "https://patchwiki.biligame.com/images/nrc/1/15/h6zi4dsluwc9f8129d9yeejo1b6rbum.png"},
        {"token": "[吃瓜]", "name": "吃瓜", "file": "ChatEmoji_3.png", "url": "https://patchwiki.biligame.com/images/nrc/c/cf/n6x3h5w0g4x1hnug6d0wjgzvdzs56np.png"},
        {"token": "[大佬]", "name": "大佬", "file": "ChatEmoji_4.png", "url": "https://patchwiki.biligame.com/images/nrc/b/b4/0m3cfzy5qp7iolix2zvxuxkh0jbk1qg.png"},
        {"token": "[感谢]", "name": "感谢", "file": "ChatEmoji_5.png", "url": "https://patchwiki.biligame.com/images/nrc/9/95/hkpw8w7bkwhasqc2ltwezvircqv3292.png"},
        {"token": "[欢迎]", "name": "欢迎", "file": "ChatEmoji_6.png", "url": "https://patchwiki.biligame.com/images/nrc/0/0f/tqg4ibbc9b6kb7xkq05h25q6ymvlpfc.png"},
        {"token": "[开摆]", "name": "开摆", "file": "ChatEmoji_7.png", "url": "https://patchwiki.biligame.com/images/nrc/a/a0/78c8q9b6c8jm6uqmg0d2b1nd5qcp6dx.png"},
        {"token": "[冲鸭]", "name": "冲鸭", "file": "ChatEmoji_8.png", "url": "https://patchwiki.biligame.com/images/nrc/6/63/37vid8ppj5a7ld282iedk53tmsr5gwe.png"},
        {"token": "[牛逼]", "name": "牛逼", "file": "ChatEmoji_9.png", "url": "https://patchwiki.biligame.com/images/nrc/6/67/pxjx3biif4dbo8eq8ejqt9zmf5chw38.png"},
        {"token": "[不！]", "name": "不！", "file": "ChatEmoji_10.png", "url": "https://patchwiki.biligame.com/images/nrc/3/3e/ldluv932b9mra00cwxmogp1tuht6nep.png"},
        {"token": "[哦]", "name": "哦", "file": "ChatEmoji_11.png", "url": "https://patchwiki.biligame.com/images/nrc/0/08/6dwb4fwaktwotbixmf6zq33kyrf9pe3.png"},
        {"token": "[在么]", "name": "在么", "file": "ChatEmoji_12.png", "url": "https://patchwiki.biligame.com/images/nrc/9/9e/3dgf2o3x8msbpo6lhwi9asb3bixfmve.png"},
        {"token": "[哇]", "name": "哇", "file": "ChatEmoji_13.png", "url": "https://patchwiki.biligame.com/images/nrc/c/cb/m12khr2nv1ucgypukxo9boyoqjfslo6.png"},
        {"token": "[呜呜]", "name": "呜呜", "file": "ChatEmoji_14.png", "url": "https://patchwiki.biligame.com/images/nrc/9/96/3d1yee5w0i9jaxyxxjgxjpbpcsyvw66.png"},
        {"token": "[无语]", "name": "无语", "file": "ChatEmoji_15.png", "url": "https://patchwiki.biligame.com/images/nrc/7/79/eu0g5tgzho6mujplfevh24sxo7t9qg6.png"},
        {"token": "[呱呱思考]", "name": "呱呱思考", "file": "ChatEmoji_16.png", "url": "https://patchwiki.biligame.com/images/nrc/d/df/0atxzq46olwa0kali6kw58w2anck2uz.png"},
        {"token": "[休息]", "name": "休息", "file": "ChatEmoji_20.png", "url": "https://patchwiki.biligame.com/images/nrc/4/4e/dz8z0dpoflh05swajrvyiayea6fhh9w.png"},
        {"token": "[沉默]", "name": "沉默", "file": "ChatEmoji_21.png", "url": "https://patchwiki.biligame.com/images/nrc/5/52/9h6xzd4a9e5bde488a08k8svfbg6h56.png"},
        {"token": "[哎哟]", "name": "哎哟", "file": "ChatEmoji_22.png", "url": "https://patchwiki.biligame.com/images/nrc/4/48/9yx2c8524tq01tt4hmhmg2bep49okh7.png"},
        {"token": "[送你花花]", "name": "送你花花", "file": "ChatEmoji_24.png", "url": "https://patchwiki.biligame.com/images/nrc/3/35/em49ebawfsjw0huqjktpcc9r7hnf7ri.png"},
        {"token": "[有宝箱]", "name": "有宝箱", "file": "ChatEmoji_1001.png", "url": "https://patchwiki.biligame.com/images/nrc/b/b9/sg91qjozg9otkqzdcp8j8vgkz1dz56d.png"},
        {"token": "[小飞机来啰]", "name": "小飞机来啰", "file": "ChatEmoji_1002.png", "url": "https://patchwiki.biligame.com/images/nrc/c/c1/cvjkhxk3hzww2lnmxcz38e7olkdumr2.png"},
        {"token": "[马戏表演]", "name": "马戏表演", "file": "ChatEmoji_1003.png", "url": "https://patchwiki.biligame.com/images/nrc/6/60/bwfr4cv13f18x0mazqqe8qw522dml3g.png"},
        {"token": "[洛克学习]", "name": "洛克学习", "file": "ChatEmoji_1004.png", "url": "https://patchwiki.biligame.com/images/nrc/7/74/6893de1gbpg842nguspfoqojc5rqupq.png"},
        {"token": "[洛克呐喊]", "name": "洛克呐喊", "file": "ChatEmoji_1005.png", "url": "https://patchwiki.biligame.com/images/nrc/5/54/mqjedxu2py4fpwvnnph4dyt2l7tkb09.png"},
        {"token": "[洛克起飞]", "name": "洛克起飞", "file": "ChatEmoji_1006.png", "url": "https://patchwiki.biligame.com/images/nrc/3/3e/l8fnxd8yu0rtq4gf2t6g3122ewltyyc.png"},
        {"token": "[吹笛子]", "name": "吹笛子", "file": "ChatEmoji_1007.png", "url": "https://patchwiki.biligame.com/images/nrc/d/d6/hlkw75a7sy98z7izohlvn9wg44um80a.png"},
        // END EMOJI CATALOG
    ];
    const pattern = /\[[^\[\]\r\n]{1,24}\]/g;
    const make = (className, text = '') => {
        const element = document.createElement('div');
        element.className = className; element.textContent = text; return element;
    };
    const create = () => {
        const tokens = new Map(catalog.map(item => [item.token, item]));
        const failedTokens = new Set();
        const known = token => tokens.has(token) && !failedTokens.has(token);
        const hasEmoji = text => [...String(text).matchAll(pattern)].some(match => known(match[0]));
        const image = item => {
            const wrapper = make('nrc-flowthread__emoji');
            wrapper.dataset.emojiToken = item.token;
            const img = document.createElement('img');
            img.src = item.url; img.alt = item.token; img.title = item.name;
            img.width = 48; img.height = 48; img.loading = 'lazy'; img.draggable = false;
            img.addEventListener('error', () => {
                failedTokens.add(item.token);
                wrapper.replaceWith(document.createTextNode(item.token));
            }, {once:true});
            wrapper.append(img); return wrapper;
        };
        const renderText = (parent, text) => {
            let offset = 0;
            for (const match of String(text).matchAll(pattern)) {
                if (!known(match[0])) continue;
                parent.append(document.createTextNode(text.slice(offset, match.index)), image(tokens.get(match[0])));
                offset = match.index + match[0].length;
            }
            parent.append(document.createTextNode(text.slice(offset)));
        };
        const attachCopy = container => {
            container.addEventListener('copy', event => {
                const selection = window.getSelection();
                if (!event.clipboardData || !selection?.rangeCount || !container.contains(selection.anchorNode) || !container.contains(selection.focusNode)) return;
                const fragment = selection.getRangeAt(0).cloneContents();
                if (!fragment.querySelector('.nrc-flowthread__emoji')) return;
                fragment.querySelectorAll('.nrc-flowthread__emoji').forEach(node => node.replaceWith(document.createTextNode(node.dataset.emojiToken)));
                // Preserve line breaks when the selection crosses paragraphs or replies.
                fragment.querySelectorAll('br').forEach(node => node.replaceWith(document.createTextNode('\n')));
                fragment.querySelectorAll('p,div').forEach(node => node.append(document.createTextNode('\n')));
                event.clipboardData.setData('text/plain', fragment.textContent);
                event.preventDefault();
            });
        };
        const attachComposer = ({composer, input, footer, hint, canEdit, isComposing, isExpanded}) => {
            const control = (className, text, action) => {
                const node = window.NrcDivUI.create('button');
                node.type = 'button'; node.className = className; node.textContent = text;
                node.addEventListener('click', action); return node;
            };
            let range = [0,0], recent = [];
            const rememberCaret = () => {
                // Chrome may reset an unfocused textarea selection after an inserted token.
                if (document.activeElement === input) range = [input.selectionStart,input.selectionEnd];
            };
            ['select','keyup','pointerup','blur','input'].forEach(type => input.addEventListener(type,rememberCaret));
            const preview = make('nrc-flowthread__emoji-preview'); preview.hidden = true;
            const picker = make('nrc-flowthread__emoji-picker'); picker.hidden = true;
            picker.id = 'nrc-flowthread-emoji-picker';
            picker.setAttribute('role','region'); picker.setAttribute('aria-label','选择表情');
            const toggle = control('nrc-flowthread__emoji-toggle','',() => setPicker(picker.hidden));
            toggle.setAttribute('aria-controls',picker.id); toggle.setAttribute('aria-expanded','false');
            // Font Awesome Free 6.0.0, regular face-smile; Fonticons, Inc., CC BY 4.0.
            // https://fontawesome.com/license/free — inline SVG avoids external font timing.
            const face = document.createElementNS('http://www.w3.org/2000/svg','svg');
            face.setAttribute('class','nrc-flowthread__emoji-face');
            face.setAttribute('viewBox','0 0 512 512'); face.setAttribute('fill','currentColor');
            face.setAttribute('aria-hidden','true'); face.setAttribute('focusable','false');
            const facePath = document.createElementNS('http://www.w3.org/2000/svg','path');
            facePath.setAttribute('d','M256 352C293.2 352 319.2 334.5 334.4 318.1C343.3 308.4 358.5 307.7 368.3 316.7C378 325.7 378.6 340.9 369.6 350.6C347.7 374.5 309.7 400 256 400C202.3 400 164.3 374.5 142.4 350.6C133.4 340.9 133.1 325.7 143.7 316.7C153.5 307.7 168.7 308.4 177.6 318.1C192.8 334.5 218.8 352 256 352zM208.4 208C208.4 225.7 194 240 176.4 240C158.7 240 144.4 225.7 144.4 208C144.4 190.3 158.7 176 176.4 176C194 176 208.4 190.3 208.4 208zM304.4 208C304.4 190.3 318.7 176 336.4 176C354 176 368.4 190.3 368.4 208C368.4 225.7 354 240 336.4 240C318.7 240 304.4 225.7 304.4 208zM512 256C512 397.4 397.4 512 256 512C114.6 512 0 397.4 0 256C0 114.6 114.6 0 256 0C397.4 0 512 114.6 512 256zM256 48C141.1 48 48 141.1 48 256C48 370.9 141.1 464 256 464C370.9 464 464 370.9 464 256C464 141.1 370.9 48 256 48z'); face.append(facePath);
            toggle.append(face,document.createTextNode('表情'));
            const tools = make('nrc-flowthread__emoji-tools'); tools.append(toggle,hint); footer.prepend(tools);
            composer.insertBefore(preview,footer); composer.insertBefore(picker,footer);

            const recentKey = 'flowthread-emojis:recent:v1';
            async function persistRecent() {
                try {
                    const db = await window.NrcDatabaseReady;
                    if (!db) return;
                    await new Promise((resolve,reject) => {
                        const transaction = db.transaction('state','readwrite');
                        transaction.objectStore('state').put({key:recentKey,type:'flowthread-emojis',version:1,tokens:recent});
                        transaction.oncomplete = resolve; transaction.onerror = () => reject(transaction.error);
                        transaction.onabort = () => reject(transaction.error);
                    });
                } catch (_) { /* Recent history is optional; posting never waits for it. */ }
            }
            async function restoreRecent() {
                try {
                    const db = await window.NrcDatabaseReady;
                    if (!db) return;
                    const saved = await new Promise((resolve,reject) => {
                        const request = db.transaction('state','readonly').objectStore('state').get(recentKey);
                        request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
                    });
                    if (saved?.version !== 1 || !Array.isArray(saved.tokens)) return;
                    recent = [...new Set([...recent,...saved.tokens.filter(token => tokens.has(token))])].slice(0,6);
                } catch (_) { /* Storage may be unavailable in private browsing. */ }
            }
            void restoreRecent();
            function refresh() {
                if (isComposing()) return;
                preview.replaceChildren();
                preview.hidden = !isExpanded() || !hasEmoji(input.value);
                if (!preview.hidden) {
                    preview.append(make('nrc-flowthread__emoji-preview-title','发送预览'));
                    renderText(preview,input.value);
                }
            }
            function insert(item) {
                if (!canEdit() || isComposing()) return;
                const [start,end] = range;
                if (input.value.length - (end-start) + item.token.length > input.maxLength) {
                    hint.textContent = '已达到评论字数上限'; return;
                }
                input.setRangeText(item.token,start,end,'end');
                range = [start+item.token.length,start+item.token.length];
                input.dispatchEvent(new Event('input',{bubbles:true}));
                recent = [item.token,...recent.filter(token => token !== item.token)].slice(0,6);
                void persistRecent();
            }
            function populate() {
                picker.replaceChildren();
                for (const [name,items] of [['最近使用',recent.map(token => tokens.get(token)).filter(Boolean)],['全部表情',catalog]]) {
                    if (!items.length) continue;
                    picker.append(make('nrc-flowthread__emoji-section',name));
                    const grid = make('nrc-flowthread__emoji-grid');
                    for (const item of items) {
                        const option = control('nrc-flowthread__emoji-option','',() => insert(item));
                        option.setAttribute('aria-label',item.name); option.dataset.token = item.token;
                        const img = document.createElement('img'); img.src = item.url; img.alt = ''; img.loading = 'lazy';
                        img.width = 48; img.height = 48; img.draggable = false;
                        img.addEventListener('error',() => { img.hidden = true; },{once:true});
                        option.append(img,document.createTextNode(item.name)); grid.append(option);
                    }
                    picker.append(grid);
                }
            }
            function setPicker(open) {
                open = open && canEdit() && !isComposing();
                picker.hidden = !open; toggle.setAttribute('aria-expanded',String(open));
                if (open) {
                    populate(); picker.querySelector('.nrc-flowthread__emoji-option')?.focus({preventScroll:true});
                }
            }
            const closePicker = () => {
                const wasOpen = !picker.hidden;
                setPicker(false); return wasOpen;
            };
            function sync() {
                toggle.disabled = !canEdit() || isComposing();
                if (!canEdit() || !isExpanded()) closePicker();
                if (!isExpanded()) preview.hidden = true;
            }
            input.addEventListener('input',refresh);
            input.addEventListener('compositionend',() => queueMicrotask(() => { refresh(); sync(); }));
            input.addEventListener('compositionstart',() => { closePicker(); toggle.disabled = true; });
            input.addEventListener('focus',closePicker);
            input.addEventListener('keydown',event => {
                if (event.key !== 'Backspace' || isComposing() || input.selectionStart !== input.selectionEnd) return;
                const caret = input.selectionStart;
                const match = [...input.value.slice(0,caret).matchAll(pattern)].find(match => match.index+match[0].length === caret && tokens.has(match[0]));
                if (!match) return;
                event.preventDefault(); input.setRangeText('',match.index,caret,'end'); rememberCaret();
                input.dispatchEvent(new Event('input',{bubbles:true}));
            });
            picker.addEventListener('keydown',event => {
                if (event.key === 'Escape') {
                    event.preventDefault(); event.stopPropagation(); closePicker(); toggle.focus();
                }
            });
            toggle.addEventListener('keydown',event => {
                if (event.key !== 'Escape') return;
                event.preventDefault(); event.stopPropagation(); closePicker();
                input.focus(); input.setSelectionRange(...range);
            });
            return {refresh,sync,closePicker,reset() { range=[0,0]; closePicker(); refresh(); }};
        };
        return {renderText,attachComposer,attachCopy};
    };
    window.NrcFlowThreadEmojis = {create};
}());

/* Generated from NRC FlowThread.js; refresh with prepare_point_comments.py. */
(function () {
    "use strict";
    window.NrcPointFlowThread = {mount(host, options) {
        const {articleId, api} = options;
        if (!Number.isSafeInteger(articleId) || articleId <= 0) throw new Error("Invalid comment page");
        const config = {}, params = new URLSearchParams(), manageMode = false, filter = "all";
        const reportError = (label, error) => window.console?.error?.("[Point comments] " + label, error);
        let disposed = false;
        const emojis = window.NrcFlowThreadEmojis?.create();
        let emojiComposer = null;
        const root = window.NrcDivUI.create("section");
        const trigger = window.NrcDivUI.create("button");
        const triggerArt = document.createElement("img");
        const triggerIcon = document.createElement("span");
        const triggerBadge = document.createElement("span");
        const panel = window.NrcDivUI.create("aside");
        const panelHeader = window.NrcDivUI.create("header");
        const panelTitle = window.NrcDivUI.create("h2");
        const panelCount = document.createElement("span");
        const closeButton = window.NrcDivUI.create("button");
        const panelBody = document.createElement("div");
        const composer = document.createElement("div");
        const composerOpen = window.NrcDivUI.create("button");
        const composerMeta = document.createElement("div");
        const composerTarget = document.createElement("span");
        const composerCancel = window.NrcDivUI.create("button");
        const composerInput = document.createElement("textarea");
        const composerFooter = document.createElement("div");
        const composerHint = document.createElement("span");
        const composerStatus = document.createElement("div");
        const composerAction = window.NrcDivUI.create("button");
        const listToolbar = document.createElement("div");
        const listTitle = document.createElement("strong");
        const refreshButton = window.NrcDivUI.create("button");
        const list = document.createElement("div");
        const pager = window.NrcDivUI.create("nav");
        const previousButton = window.NrcDivUI.create("button");
        const nextButton = window.NrcDivUI.create("button");
        const emptyState = document.createElement("div");
        const loadingState = document.createElement("div");
        const errorState = document.createElement("div");
        const reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

        root.id = "nrc-point-flowthread-root";
        root.className = "nrc-flowthread";
        root.classList.toggle("is-manage", manageMode);
        trigger.type = "button";
        trigger.className = "nrc-flowthread__trigger";
        trigger.setAttribute("aria-label", "打开评论");
        trigger.setAttribute("aria-controls", "nrc-point-flowthread-panel");
        trigger.setAttribute("aria-expanded", "false");
        trigger.title = "评论";
        triggerArt.className = "nrc-flowthread__trigger-art";
        // Wiki 文件名：Scroll_Control_Base.png。保留滚动按钮轮廓的无图案底。
        triggerArt.src = "https://patchwiki.biligame.com/images/nrc/7/73/ln4k0pzay7mosf0q14qdu6kasm56v67.png";
        triggerArt.alt = "";
        triggerArt.width = 44;
        triggerArt.height = 44;
        triggerArt.draggable = false;
        triggerIcon.className = "nrc-flowthread__trigger-icon fa-solid fa-comment-dots";
        triggerIcon.setAttribute("aria-hidden", "true");
        triggerBadge.className = "nrc-flowthread__badge";
        triggerBadge.hidden = true;
        trigger.append(triggerArt, triggerIcon, triggerBadge);

        panel.id = "nrc-point-flowthread-panel";
        panel.className = "nrc-flowthread__panel";
        panel.hidden = true;
        panel.setAttribute("role", "region");
        panel.setAttribute("aria-label", "评论");
        panelHeader.className = "nrc-flowthread__header";
        panelTitle.className = "nrc-flowthread__title";
        panelTitle.textContent = "点位评论";
        panelCount.className = "nrc-flowthread__count";
        closeButton.type = "button";
        closeButton.className = "nrc-flowthread__close";
        closeButton.setAttribute("aria-label", "关闭评论");
        closeButton.title = "关闭";
        closeButton.textContent = "×";
        panelHeader.append(panelTitle, panelCount, closeButton);

        listToolbar.className = "nrc-flowthread__toolbar";
        listTitle.className = "nrc-flowthread__list-title";
        listTitle.textContent = manageMode ? `管理：${filter}` : "最新评论";
        refreshButton.type = "button";
        refreshButton.className = "nrc-flowthread__refresh";
        refreshButton.textContent = "刷新";
        refreshButton.title = "刷新评论";
        listToolbar.append(listTitle, refreshButton);

        panelBody.className = "nrc-flowthread__body";
        list.className = "nrc-flowthread__list";
        emptyState.className = "nrc-flowthread__state nrc-flowthread__state--empty";
        emptyState.textContent = "还没有评论";
        loadingState.className = "nrc-flowthread__state nrc-flowthread__state--loading";
        loadingState.textContent = "正在加载评论…";
        errorState.className = "nrc-flowthread__state nrc-flowthread__state--error";
        errorState.textContent = "评论加载失败，请稍后重试";
        panelBody.append(listToolbar, list, emptyState, loadingState, errorState);

        composer.className = "nrc-flowthread__composer";
        composerStatus.className = "nrc-flowthread__composer-status";
        composerStatus.setAttribute("role", "status");
        composerStatus.setAttribute("aria-live", "polite");
        composerStatus.hidden = true;
        composerOpen.type = "button";
        composerOpen.className = "nrc-flowthread__composer-open";
        composerOpen.setAttribute("aria-controls", "nrc-point-flowthread-input");
        composerOpen.setAttribute("aria-expanded", "false");
        composerOpen.textContent = "发表评论";
        composerMeta.className = "nrc-flowthread__composer-meta";
        composerTarget.className = "nrc-flowthread__reply-target";
        composerCancel.type = "button";
        composerCancel.className = "nrc-flowthread__composer-cancel";
        composerCancel.textContent = "收起";
        composerMeta.append(composerTarget, composerCancel);
        composerInput.id = "nrc-point-flowthread-input";
        composerInput.className = "nrc-flowthread__input";
        composerInput.rows = 3;
        composerInput.maxLength = 1000;
        composerInput.value = options.draft?.text || "";
        composerInput.placeholder = "登录后参与评论…";
        composerFooter.className = "nrc-flowthread__composer-footer";
        composerHint.className = "nrc-flowthread__composer-hint";
        composerAction.type = "submit";
        composerAction.className = "nrc-flowthread__submit";
        composerAction.textContent = "发表评论";
        composerFooter.append(composerHint, composerAction);
        composer.append(composerStatus, composerOpen, composerMeta, composerInput, composerFooter);

        pager.className = "nrc-flowthread__pager";
        previousButton.type = "button";
        previousButton.className = "nrc-flowthread__page-button";
        previousButton.textContent = "上一页";
        nextButton.type = "button";
        nextButton.className = "nrc-flowthread__page-button";
        nextButton.textContent = "下一页";
        pager.append(previousButton, nextButton);

        panel.append(panelHeader, panelBody, composer, pager);
        root.append(trigger, panel);
        host.replaceChildren(root);

        let panelOpen = false;
        let loading = false;
        let page = Math.max(0, Number(params.get("offset") || 0));
        let pageCount = 1;
        let replyTarget = null, replyPost = null;
        let currentPosts = [];
        let composing = false;
        let composerExpanded = false;
        let posting = false;
        const likeOverrides = new Map();
        const storedLikeStates = new Map();
        let likeStateReady = Promise.resolve();
        let panelCloseTimer;
        let panelOpenFrame;

        const isLoggedIn = () => api.available;
        const openLogin = () => api.login();
        const getCurrentUserId = () => {
            const info = window.UserStatus?.userInfo;
            if (info?.mid) {
                return String(info.mid);
            }
            const match = document.cookie.match(/(?:^|;\s*)DedeUserID=([^;]+)/);
            if (!match) {
                return "";
            }
            try {
                return decodeURIComponent(match[1]);
            } catch (error) {
                reportError("decode current user id", error);
                return match[1];
            }
        };
        const currentUserId = api.userId || getCurrentUserId();
        const gameName = "rocom";
        const likeStateKey = currentUserId && articleId
            ? `flowthread-likes:${gameName}:${currentUserId}:${articleId}`
            : "";
        const readLikeState = async () => {
            if (!likeStateKey || !window.NrcDatabaseReady) {
                return null;
            }
            const database = await window.NrcDatabaseReady;
            if (!database) {
                return null;
            }
            return new Promise((resolve, reject) => {
                const request = database.transaction("state", "readonly")
                    .objectStore("state")
                    .get(likeStateKey);
                request.addEventListener("success", () => resolve(request.result || null), { once: true });
                request.addEventListener("error", () => reject(request.error), { once: true });
            });
        };
        const writeLikeState = async () => {
            if (!likeStateKey || !window.NrcDatabaseReady) {
                return false;
            }
            const database = await window.NrcDatabaseReady;
            if (!database) {
                return false;
            }
            const likes = Object.fromEntries(storedLikeStates);
            return new Promise((resolve, reject) => {
                const transaction = database.transaction("state", "readwrite");
                transaction.objectStore("state").put({
                    key: likeStateKey,
                    type: "flowthread-likes",
                    version: 1,
                    userId: currentUserId,
                    articleId,
                    likes,
                    updatedAt: Date.now()
                });
                transaction.addEventListener("complete", () => resolve(true), { once: true });
                transaction.addEventListener("error", () => reject(transaction.error), { once: true });
                transaction.addEventListener("abort", () => reject(transaction.error), { once: true });
            });
        };
        const restoreLikeStates = async () => {
            try {
                const record = await readLikeState();
                if (record?.version !== 1 || !record.likes || typeof record.likes !== "object") {
                    return;
                }
                Object.entries(record.likes).forEach(([postId, liked]) => {
                    if (typeof liked === "boolean") {
                        storedLikeStates.set(postId, liked);
                    }
                });
            } catch (error) {
                reportError("read FlowThread like states", error);
            }
        };
        likeStateReady = restoreLikeStates();
        const resetReply = () => {
            replyTarget = null; replyPost = null;
            composerTarget.textContent = "";
            composerCancel.textContent = "收起";
            composerInput.placeholder = isLoggedIn() ? "写下你的评论…" : "登录后参与评论…";
        };
        const setComposer = (expanded, post = null) => {
            if (posting) return;
            if (expanded && !isLoggedIn()) {
                openLogin();
                return;
            }
            composerExpanded = expanded;
            if (expanded && post) {
                replyTarget = post.id; replyPost = {id:post.id, uname:post.uname || post.username || "用户"};
                composerTarget.textContent = `回复 ${post.uname || post.username || "用户"}`;
                composerCancel.textContent = "取消回复";
                composerInput.placeholder = "写下你的回复…";
            } else if (!expanded || !replyTarget) {
                resetReply();
            }
            composer.classList.toggle("is-expanded", expanded);
            composerOpen.setAttribute("aria-expanded", expanded ? "true" : "false");
            composerAction.textContent = replyTarget ? "发表回复" : "发表评论";
            emojiComposer?.closePicker();
            emojiComposer?.sync();
            emojiComposer?.refresh();
            if (expanded) {
                window.requestAnimationFrame(() => composerInput.focus());
            }
        };
        const setPanel = (open) => {
            window.clearTimeout(panelCloseTimer);
            window.cancelAnimationFrame(panelOpenFrame);
            panelOpen = open;
            trigger.setAttribute("aria-expanded", open ? "true" : "false");
            root.classList.toggle("is-open", open);
            if (open) {
                panel.hidden = false;
                panelOpenFrame = window.requestAnimationFrame(() => {
                    panel.classList.add("is-visible");
                });
                loadPage();
            } else {
                emojiComposer?.closePicker();
                panel.classList.remove("is-visible");
                panelCloseTimer = window.setTimeout(() => {
                    if (!panelOpen) {
                        panel.hidden = true;
                    }
                }, 180);
            }
        };
        const setState = (state) => {
            [emptyState, loadingState, errorState].forEach((element) => {
                element.hidden = element !== state;
            });
        };
        const renderMarkup = (container, value) => {
            const source = typeof value === "string" ? value : "";
            const template = document.createElement("template");
            template.innerHTML = source;
            const allowed = new Set(["A", "B", "BR", "CODE", "EM", "I", "P", "SPAN", "STRONG"]);
            const visit = (node, parent, allowEmoji = true) => {
                Array.from(node.childNodes).forEach((child) => {
                    if (child.nodeType === Node.TEXT_NODE) {
                        if (emojis && allowEmoji) emojis.renderText(parent, child.nodeValue || "");
                        else parent.appendChild(document.createTextNode(child.nodeValue || ""));
                        return;
                    }
                    if (child.nodeType !== Node.ELEMENT_NODE) {
                        return;
                    }
                    if (!allowed.has(child.tagName)) {
                        visit(child, parent, allowEmoji && !["PRE", "CODE"].includes(child.tagName));
                        return;
                    }
                    const clone = document.createElement(child.tagName.toLowerCase());
                    if (child.tagName === "A" && child.getAttribute("href")) {
                        try {
                            const url = new URL(child.getAttribute("href"), window.location.href);
                            if (["http:", "https:"].includes(url.protocol)) {
                                clone.href = url.href;
                                clone.target = "_blank";
                                clone.rel = "noopener noreferrer";
                            }
                        } catch (error) {
                            reportError("parse comment link", error);
                        }
                    }
                    visit(child, clone, allowEmoji && !["A", "CODE"].includes(child.tagName));
                    parent.appendChild(clone);
                });
            };
            visit(template.content, container);
        };
        const renderReplyContext = (container, value) => {
            const template = document.createElement("template");
            template.innerHTML = typeof value === "string" ? value : "";
            container.textContent = `回复 ${template.content.textContent || ""}：`;
        };
        const formatTime = (timestamp) => {
            const date = new Date(Number(timestamp || 0) * 1000);
            if (Number.isNaN(date.getTime())) {
                return "";
            }
            return new Intl.DateTimeFormat("zh-CN", {
                month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit"
            }).format(date);
        };
        const updateLikeButton = (button, liked, count) => {
            button.classList.toggle("is-liked", liked);
            button.setAttribute("aria-pressed", liked ? "true" : "false");
            button.dataset.likeCount = String(count);
            button.textContent = `${liked ? "已赞" : "赞"} ${count}`;
        };
        const mutateLike = async (postId, button) => {
            if (button.disabled) {
                return;
            }
            const key = String(postId);
            const previousOverride = likeOverrides.get(key);
            const wasLiked = button.getAttribute("aria-pressed") === "true";
            const previousCount = Math.max(0, Number(button.dataset.likeCount) || 0);
            const liked = !wasLiked;
            const count = Math.max(0, previousCount + (liked ? 1 : -1));
            likeOverrides.set(key, { liked, count });
            updateLikeButton(button, liked, count);
            button.disabled = true;
            try {
                await api.postWithToken("csrf", {
                    action: "flowthread",
                    type: liked ? "like" : "dislike",
                    postid: postId
                });
                storedLikeStates.set(key, liked);
                try {
                    await writeLikeState();
                } catch (error) {
                    reportError("write FlowThread like states", error);
                }
                await loadPage();
            } catch (error) {
                if (previousOverride) {
                    likeOverrides.set(key, previousOverride);
                } else {
                    likeOverrides.delete(key);
                }
                updateLikeButton(button, wasLiked, previousCount);
                reportError(`flowthread ${liked ? "like" : "dislike"}`, error);
            } finally {
                button.disabled = false;
            }
        };
        const renderPost = (post, context = {}) => {
            const item = window.NrcDivUI.create("article");
            item.className = "nrc-flowthread__post";
            item.dataset.postId = (context.legacy ? "rocom-" : "") + String(post.id || "");
            if (post.parentid) {
                item.classList.add("is-reply");
            }
            const head = document.createElement("div");
            head.className = "nrc-flowthread__post-head";
            const avatar = document.createElement("img");
            avatar.className = "nrc-flowthread__post-avatar";
            avatar.alt = "";
            avatar.src = post.avatar || config.AnonymousAvatar || "https://static.hdslb.com/images/member/noface.gif";
            const identity = document.createElement("div");
            identity.className = "nrc-flowthread__post-identity";
            const name = document.createElement("strong");
            name.className = "nrc-flowthread__post-name";
            name.textContent = post.uname || post.username || "匿名用户";
            const meta = document.createElement("div");
            meta.className = "nrc-flowthread__post-meta";
            const time = document.createElement("div");
            time.className = "nrc-flowthread__post-time";
            time.textContent = formatTime(post.timestamp);
            const floor = document.createElement("span");
            floor.className = "nrc-flowthread__post-floor";
            floor.textContent = post.flowthread_floor && (!post.parentid || manageMode) ? `${post.flowthread_floor}楼` : "";
            meta.append(time, floor);
            if (context.legacy) {
                const badge = document.createElement("span");
                badge.className = "nrc-flowthread__legacy-badge";
                badge.textContent = "历史";
                meta.append(badge);
            }
            identity.append(name, meta);
            head.append(avatar, identity);
            const content = document.createElement("div");
            content.className = "nrc-flowthread__post-content";
            if (post.parent_username) {
                const context = document.createElement("span");
                context.className = "nrc-flowthread__reply-context";
                renderReplyContext(context, post.parent_username);
                content.append(context);
            }
            renderMarkup(content, post.text || "");
            const actions = document.createElement("div");
            actions.className = "nrc-flowthread__post-actions";
            const addAction = (label, handler, className = "") => {
                const button = window.NrcDivUI.create("button");
                button.type = "button";
                button.className = `nrc-flowthread__post-action ${className}`.trim();
                button.textContent = label;
                button.addEventListener("click", handler);
                actions.append(button);
                return button;
            };
            if (context.legacy) {
                const likes = document.createElement("span");
                likes.className = "nrc-flowthread__legacy-likes";
                likes.textContent = `赞 ${Math.max(0, Number(post.like) || 0)}`;
                actions.append(likes);
                const report = addAction("举报", () => context.report(post.id, report));
            } else if (!manageMode) {
                addAction("回复", () => {
                    setComposer(true, post);
                });
                if (isLoggedIn()) {
                    const likeOverride = likeOverrides.get(String(post.id));
                    const storedLikeState = storedLikeStates.get(String(post.id));
                    const liked = likeOverride
                        ? likeOverride.liked
                        : typeof storedLikeState === "boolean"
                            ? storedLikeState
                            : Number(post.myatt) === 1;
                    const likeCount = likeOverride
                        ? likeOverride.count
                        : Math.max(0, Number(post.like) || 0);
                    const likeButton = addAction(
                        "",
                        () => mutateLike(post.id, likeButton),
                        liked ? "is-liked" : ""
                    );
                    updateLikeButton(likeButton, liked, likeCount);
                    addAction("举报", () => mutatePost("report", post.id));
                }
            } else {
                addAction(post.deleted ? "恢复" : "删除", () => mutatePost(post.deleted ? "recover" : "delete", post.id));
                if (config.FlowThreadAdmin) {
                    addAction("标记已检查", () => mutatePost("markchecked", post.id));
                    if (post.deleted) {
                        addAction("永久删除", () => mutatePost("erase", post.id));
                    }
                }
            }
            item.append(head, content, actions);
            return item;
        };
        const renderPosts = (data) => {
            list.replaceChildren();
            const records = new Map();
            for (const post of manageMode ? (data.posts || []) : [...(data.popular || []), ...(data.posts || [])]) {
                records.set(String(post.id), post);
            }
            currentPosts = [...records.values()];
            const appendSection = (label, posts, render = renderPost) => {
                if (!posts.length) return;
                const heading = window.NrcDivUI.create("h3");
                heading.className = "nrc-flowthread__section-heading";
                heading.textContent = label;
                list.append(heading);
                posts.forEach((post) => list.append(render(post)));
            };
            if (manageMode) {
                appendSection("评论列表", currentPosts);
            } else {
                // API 返回扁平数组；按 parentid 建立关系后再分热门与普通楼层。
                const nodes = new Map(currentPosts.map(post => [String(post.id), {post, children: [], parent: null}]));
                for (const node of nodes.values()) {
                    const parent = nodes.get(String(node.post.parentid || ""));
                    let ancestor = parent;
                    while (ancestor && ancestor !== node) ancestor = ancestor.parent;
                    if (parent && ancestor !== node) {
                        node.parent = parent;
                        parent.children.push(node);
                    }
                }
                const popularRoots = new Set();
                for (const post of data.popular || []) {
                    let node = nodes.get(String(post.id));
                    while (node?.parent) node = node.parent;
                    if (node) popularRoots.add(node);
                }
                const roots = [...nodes.values()].filter(node => !node.parent);
                const renderThread = node => {
                    const thread = document.createElement("div");
                    thread.className = "nrc-flowthread__thread";
                    thread.dataset.threadId = String(node.post.id);
                    thread.append(renderPost(node.post));
                    const replies = document.createElement("div");
                    replies.className = "nrc-flowthread__replies";
                    const appendReplies = parent => {
                        parent.children.sort((a, b) => Number(a.post.timestamp || 0) - Number(b.post.timestamp || 0));
                        for (const child of parent.children) {
                            replies.append(renderPost(child.post));
                            appendReplies(child);
                        }
                    };
                    appendReplies(node);
                    if (replies.childElementCount) thread.append(replies);
                    return thread;
                };
                appendSection("热门评论", roots.filter(node => popularRoots.has(node)), renderThread);
                appendSection("全部评论", roots.filter(node => !popularRoots.has(node)), renderThread);
            }
            const count = Number(data.count) || 0;
            panelCount.textContent = count ? `${count} 条` : "";
            triggerBadge.textContent = count > 99 ? "99+" : String(count);
            triggerBadge.hidden = count <= 0;
            pageCount = Math.max(1, Math.ceil(count / (manageMode ? 20 : 10)));
            previousButton.disabled = page <= 0;
            nextButton.disabled = page >= pageCount - 1;
            setState(currentPosts.length ? null : emptyState);
        };
        const loadPage = async () => {
            if (loading || disposed) return;
            loading = true;
            setState(loadingState);
            try {
                await likeStateReady;
                const query = manageMode
                    ? { action: "flowthread", type: "listall", page: window.mw.config.get("wgPageName"), offset: page, limit: 20, filter, dir: "older" }
                    : { action: "flowthread", type: "list", pageid: articleId, offset: page * 10, utf8: "" };
                const result = await api.get(query);
                if (!disposed) renderPosts(result.flowthread || {});
            } catch (error) {
                if (!disposed) setState(errorState);
                reportError("load comments", error);
            } finally {
                loading = false;
            }
        };
        const mutatePost = async (type, postId) => {
            try {
                await api.postWithToken("csrf", { action: "flowthread", type, postid: postId });
                await loadPage();
            } catch (error) {
                reportError(`flowthread ${type}`, error);
            }
        };
        const setComposerState = () => {
            const loggedIn = isLoggedIn();
            if (!loggedIn && composerExpanded) {
                composerExpanded = false;
                composer.classList.remove("is-expanded");
                composerOpen.setAttribute("aria-expanded", "false");
                resetReply();
            }
            composer.classList.toggle("is-logged-out", !loggedIn);
            composerInput.disabled = !loggedIn || posting;
            composerAction.disabled = !loggedIn || posting;
            composerCancel.disabled = posting;
            composerOpen.disabled = posting;
            composerHint.textContent = "评论限 1000 字";
            composerAction.textContent = posting ? "提交中…" : replyTarget ? "发表回复" : "发表评论";
            composerOpen.textContent = loggedIn ? "发表评论" : "登录后参与评论";
            emojiComposer?.sync();
        };
        if (emojis) {
            emojis.attachCopy(list);
            if (!manageMode) emojiComposer = emojis.attachComposer({
                composer, input: composerInput, footer: composerFooter, hint: composerHint,
                canEdit: () => isLoggedIn() && !posting,
                isComposing: () => composing,
                isExpanded: () => composerExpanded
            });
        }
        setComposerState();
        trigger.addEventListener("click", () => setPanel(!panelOpen));
        closeButton.addEventListener("click", () => setPanel(false));
        refreshButton.addEventListener("click", () => loadPage());
        previousButton.addEventListener("click", () => { page = Math.max(0, page - 1); loadPage(); });
        nextButton.addEventListener("click", () => { page = Math.min(pageCount - 1, page + 1); loadPage(); });
        composerOpen.addEventListener("click", () => setComposer(true));
        composerCancel.addEventListener("click", () => setComposer(false));
        composerInput.addEventListener("compositionstart", () => { composing = true; });
        composerInput.addEventListener("compositionend", () => { composing = false; });
        composerInput.addEventListener("input", () => {
            if (!composing && composerInput.value.length > 1000) {
                composerInput.value = composerInput.value.slice(0, 1000);
            }
        });
        composerAction.addEventListener("click", () => composer.dispatchEvent(new Event("submit", {cancelable:true})));
        const saveDraft = () => options.saveDraft({text:composerInput.value, reply:replyPost});
        composerInput.addEventListener("input", saveDraft);
        composer.addEventListener("submit", async (event) => {
            event.preventDefault();
            if (posting) return;
            if (!isLoggedIn()) { openLogin(); return; }
            const text = composerInput.value.trim();
            if (!text) return;
            const submittedParent = replyTarget;
            const showStatus = (message, state) => {
                composerStatus.textContent = message;
                composerStatus.dataset.state = state;
                composerStatus.hidden = false;
            };
            let accepted = false, awaitingReview = false;
            posting = true;
            options.onSubmitStart();
            setComposerState();
            showStatus("正在提交…", "pending");
            try {
                // mw.Api 的拒绝参数为 (code, response)；直接 await 会丢失 response.error.info。
                await new Promise((resolve, reject) => {
                    api.postWithToken("csrf", {
                        action: "flowthread", type: "post", pageid: articleId,
                        postid: submittedParent || "", content: text, wikitext: false
                    }).then(result => result?.error ? reject(result) : resolve(result),
                        (code, response) => reject(response || code));
                });
                accepted = true;
                showStatus("评论已发表。", "success");
            } catch (error) {
                const info = String(error?.error?.info || error?.info || error?.message || "");
                awaitingReview = /审核中|待审核|等待审核/.test(info);
                if (awaitingReview) {
                    accepted = true;
                    showStatus("评论已提交，正在审核，通过后会显示。请勿重复提交。", "pending");
                } else {
                    showStatus(info || "提交失败，内容已保留，请稍后重试。", "error");
                }
            } finally {
                posting = false;
                if (accepted) {
                    composerInput.value = "";
                    saveDraft();
                    setComposer(false);
                    emojiComposer?.reset();
                }
                setComposerState();
                options.onSubmitEnd({text:composerStatus.textContent, state:composerStatus.dataset.state});
            }
            if (accepted && !awaitingReview) {
                if (!submittedParent) page = 0;
                await loadPage();
            }
        });

        trigger.hidden = true;
        closeButton.hidden = true;
        panel.hidden = false;
        panel.classList.add("is-visible");
        root.addEventListener("keydown", event => {
            if (event.key === "Escape" && emojiComposer?.closePicker()) {
                event.preventDefault(); event.stopPropagation();
            }
        });
        const interval = window.setInterval(setComposerState, 1000);
        if (options.draft?.text && isLoggedIn()) setComposer(true, options.draft.reply);
        if (options.lastStatus) {
            composerStatus.textContent = options.lastStatus.text;
            composerStatus.dataset.state = options.lastStatus.state;
            composerStatus.hidden = false;
        }
        loadPage();
        return {destroy() {
            disposed = true;
            saveDraft();
            window.clearInterval(interval);
            window.clearTimeout(panelCloseTimer);
            window.cancelAnimationFrame(panelOpenFrame);
            emojiComposer?.closePicker();
            root.remove();
        }};
    }};
}());

  if (window.mw?.hook) mw.hook("wikipage.content").add(scan);
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", scan, {once:true});
  else scan();
}());