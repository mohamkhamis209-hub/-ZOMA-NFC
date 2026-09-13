async function writeNfc(url){
 if(!("NDEFReader" in window)) throw new Error("Web NFC غير مدعوم على هذا الجهاز/المتصفح");
 const ndef=new NDEFReader(); await ndef.write({records:[{recordType:"url",data:url}]}); return true;
}