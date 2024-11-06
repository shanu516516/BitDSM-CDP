"use strict";exports.id=551,exports.ids=[551],exports.modules={58933:(t,n,e)=>{function r(t,n){let e=btoa(function(t){let n="";for(let e=0;e<t.length;e+=1)n+=String.fromCharCode(t[e]);return n}(t)).replace(/=/g,"");return n?e.replace(/\+/g,"-").replace(/\//g,"_"):e}function i(){return BigInt("115792089210356248762697446949407573530086143415290314195533631308867097853951")}function o(){return BigInt("0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b")}function l(t){return BigInt("0x"+function(t){let n="";for(let e=0;e<t.length;e++){let r=t[e].toString(16);n+=r.length>1?r:"0"+r}return n}(t))}function u(t,n){let e=t.toString(16),r=2*n,i="";if(r<e.length)throw Error(`cannot pack integer with ${e.length} hex chars into ${n} bytes`);return function(t){if(t.length%2!=0)throw Error("Hex string length must be multiple of 2");let n=new Uint8Array(t.length/2);for(let e=0;e<t.length;e+=2)n[e/2]=parseInt(t.substring(e,e+2),16);return n}("0".repeat(r-e.length)+e)}function g(t,n){return(t&BigInt(1)<<BigInt(n))!==BigInt(0)}e.d(n,{Y:()=>h});var a=e(13092);function h(t){let{uncompressedPrivateKeyHex:n,compressedPublicKeyHex:e}=t,h=function(t){if(33!==t.length&&65!==t.length)throw Error("Invalid length: point is not in compressed or uncompressed format");if((2===t[0]||3===t[0])&&33==t.length){let n=3===t[0],e=l(t.subarray(1,t.length)),a=i();if(e<BigInt(0)||e>=a)throw Error("x is out of range");let h=function(t,n){let e=i(),r=function(t,n){if(n<=BigInt(0))throw Error("p must be positive");let e=t%n;if(g(n,0)&&g(n,1)){let t=function(t,n,e){if(n===BigInt(0))return BigInt(1);let r=t,i=n.toString(2);for(let n=1;n<i.length;++n)r=r*r%e,"1"===i[n]&&(r=r*t%e);return r}(e,n+BigInt(1)>>BigInt(2),n);if(t*t%n!==e)throw Error("could not find a modular square root");return t}throw Error("unsupported modulus value")}(((t*t+(e-BigInt(3)))*t+o())%e,e);return n!==g(r,0)&&(r=(e-r)%e),r}(e,n);return{kty:"EC",crv:"P-256",x:r(u(e,32),!0),y:r(u(h,32),!0),ext:!0}}if(4===t[0]&&65==t.length){let n=l(t.subarray(1,33)),e=l(t.subarray(33,65)),g=i();if(n<BigInt(0)||n>=g||e<BigInt(0)||e>=g||!function(t,n){let e=i(),r=e-BigInt(3),l=o();return n**BigInt(2)%e==((t*t+r)*t+l)%e}(n,e))throw Error("invalid uncompressed x and y coordinates");return{kty:"EC",crv:"P-256",x:r(u(n,32),!0),y:r(u(e,32),!0),ext:!0}}throw Error("invalid format")}((0,a.q8)(e));return h.d=(0,a.bN)(n,a.HS),h}},50551:(t,n,e)=>{e.r(n),e.d(n,{signWithApiKey:()=>o});var r=e(58933),i=e(13092);let o=async t=>{let{content:n,publicKey:e,privateKey:r}=t,i=await l({uncompressedPrivateKeyHex:r,compressedPublicKeyHex:e});return await u({key:i,content:n})};async function l(t){let{uncompressedPrivateKeyHex:n,compressedPublicKeyHex:e}=t,i=(0,r.Y)({uncompressedPrivateKeyHex:n,compressedPublicKeyHex:e});return await crypto.subtle.importKey("jwk",i,{name:"ECDSA",namedCurve:"P-256"},!1,["sign"])}async function u(t){let{key:n,content:e}=t,r=function(t){let n;if(t.length%2!=0||0==t.length||t.length>132)throw Error("Invalid IEEE P1363 signature encoding. Length: "+t.length);let e=g(t.subarray(0,t.length/2)),r=g(t.subarray(t.length/2,t.length)),i=0,o=2+e.length+1+1+r.length;return o>=128?((n=new Uint8Array(o+3))[i++]=48,n[i++]=129):(n=new Uint8Array(o+2))[i++]=48,n[i++]=o,n[i++]=2,n[i++]=e.length,n.set(e,i),i+=e.length,n[i++]=2,n[i++]=r.length,n.set(r,i),n}(new Uint8Array(await crypto.subtle.sign({name:"ECDSA",hash:"SHA-256"},n,new TextEncoder().encode(e))));return(0,i.fv)(r)}function g(t){let n=0;for(;n<t.length&&0==t[n];)n++;n==t.length&&(n=t.length-1);let e=0;(128&t[n])==128&&(e=1);let r=new Uint8Array(t.length-n+e);return r.set(t.subarray(n),e),r}}};