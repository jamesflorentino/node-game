((function(){String.prototype.randomId=function(a){var b,c,d;a==null&&(a=10),d="abcdefghijklmopqrstuvwxyz0123456789",c="";while(a-->-1)b=Math.random()*d.length,c+=d.substr(b,1);return c},Array.prototype.random=function(){var a;return a=Math.random()*(this.length-1),a=Math.round(a),this[a]},Array.prototype.last=function(){return this[this.length-1]},window.implement=function(a,b){var c;if(b instanceof Object)for(c in b)a[c]=b[c]},window.after=function(a,b){return setTimeout(b,a)}})).call(this)