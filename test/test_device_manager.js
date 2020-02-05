const DeviceManager = artifacts.require("DeviceManager");
const BigNumber = require('bignumber.js');
const test_uri = "test_uri";

contract("DeviceManager", (accounts) => {
  let dm;
  let ids = [];
  before(async ()=>{
    dm = await DeviceManager.deployed();
  });

  it("test produce function", async () => {
    const result = await dm.produce.sendTransaction(test_uri);
    const id1 = result.receipt.logs[1].args.device_id.toNumber();
    ids[0] = id1;
    assert.equal(id1,1,"id is not 1");
    const got_uri = await dm.tokenURI.call(id1);
    assert.equal(got_uri,test_uri,"uri error");
  });

  it("test assemble function", async ()=>{
    const result2 = await dm.produce.sendTransaction(test_uri);
    const id2 = result2.receipt.logs[1].args.device_id.toNumber();
    const result3 = await dm.produce.sendTransaction(test_uri);
    const id3 = result3.receipt.logs[1].args.device_id.toNumber();
    ids[1] = id2;
    ids[2] = id3;
    const parts = [ids[0],id2,id3];
    const result4 = await dm.assemble.sendTransaction(parts,test_uri);
    const logs4 = result4.receipt.logs;
    const id4 = logs4[logs4.length-1].args.device_id.toNumber();
    ids[3] = id4;
    assert.equal(id4,4,"id is not 4");
    const got_uri = await dm.tokenURI.call(id4);
    assert.equal(got_uri,test_uri,"uri error");
    let i;
    let got_parts_of_deviceId = [];
    for(i=0;i<parts.length;i++) {
      got_parts_of_deviceId[i] = await dm.parts_of_deviceId.call(id4,i);
    }
    got_parts_of_deviceId = got_parts_of_deviceId.map(v=>v.toNumber());
    assert.deepStrictEqual(got_parts_of_deviceId,parts,"parts error");
    let got_assembles = [];
    for(i=0;i<parts.length;i++){
      got_assembles[i] = await dm.assembly_of_deviceId.call(parts[i]);
    }
    got_assembles = got_assembles.map(v=>v.toNumber());
    assert.deepStrictEqual(got_assembles,[id4,id4,id4],"assemble error");
  });

  it("test disassemble function", async ()=>{
    const result5 = await dm.disassemble.sendTransaction(ids[3]);
    const logs5 = result5.receipt.logs;
    const assembled_id= logs5[logs5.length-1].args.device_id.toNumber();
    assert.equal(assembled_id,ids[3],"id is not 4");
    let i; let log; let bn_from;
    let parts = [];
    for(i=0;i<logs5.length;i++) {
      log = logs5[i];
      bn_from = new BigNumber(log.args.from,16);
      if(log.event==="Transfer"&&bn_from==0){
        parts.push(log.args.tokenId.toNumber());
        continue;
      }
    }
    assert.deepStrictEqual(parts,ids.slice(0,3),"disassembling error");
    let got_uris = [];
    for(i=0;i<parts.length;i++){
      got_uris.push(await dm.tokenURI.call(parts[i]));
    }
    assert.deepStrictEqual(got_uris,[test_uri,test_uri,test_uri],"uri error");
    let got_assembles = [];
    for(i=0;i<parts.length;i++){
      got_assembles.push(await dm.assembly_of_deviceId.call(parts[i]));
    }
    got_assembles = got_assembles.map(v=>v.toNumber());
    assert.deepStrictEqual(got_assembles,[0,0,0],"assemble error");
  });

  it("test dispose function", async ()=>{
    const result6 = await dm.dispose.sendTransaction(ids[1]);
    const disposed_id1 = result6.receipt.logs[1].args.device_id.toNumber();
    assert.equal(disposed_id1,ids[1],"disposed_id1 is not 1");
    const got_uri_id6 = await dm.uri_of_deviceId.call(disposed_id1);
    assert.equal(got_uri_id6,"","uri_id6 is not empty");
    const result7 = await dm.assemble.sendTransaction([ids[0],ids[2]],test_uri);
    const logs7 = result7.receipt.logs;
    const id5 = logs7[logs7.length-1].args.device_id.toNumber();
    assert.equal(id5,5,"disposed_id5 is not 5");
    const result8 = await dm.dispose.sendTransaction(id5);
    const log8 = result8.receipt.logs;
    let i; let log;
    let parts = [];
    for(i=0;i<log8.length;i++) {
      log = log8[i];
      if(log.event==="Dispose") {
        parts.push(log.args.device_id.toNumber());
        continue;
      }
    }
    assert.deepStrictEqual(parts,[ids[0],ids[2]],"disposing error");
    let got_uris = [];
    for(i=0;i<parts.length;i++){
      got_uris.push(await dm.uri_of_deviceId.call(parts[i]));
    }
    assert.deepStrictEqual(got_uris,["",""],"uri error");
  });

});
