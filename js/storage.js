async function uploadAsset(file,folder){
 if(!file) throw new Error("اختر ملفًا");
 if(file.size>5*1024*1024) throw new Error("الحد الأقصى 5MB");
 const ext=(file.name.split(".").pop()||"bin").toLowerCase();
 const path=`${folder}/${crypto.randomUUID()}.${ext}`;
 const {error}=await db.storage.from("zoma-assets").upload(path,file,{upsert:false});
 if(error)throw error;
 const {data}=db.storage.from("zoma-assets").getPublicUrl(path);
 return data.publicUrl;
}