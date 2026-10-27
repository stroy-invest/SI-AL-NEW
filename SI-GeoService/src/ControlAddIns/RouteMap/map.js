/* Self-contained route viewer: no third-party JavaScript dependencies.
   GeoJSON coordinates use [longitude, latitude]. OSM tiles are visual context only. */
(function () {
    'use strict';
    var state = {points: [], start: null, end: null, zoom: 12, center: [35.05,48.46], drag: null};
    var map, tiles, overlay, route, startMarker, endMarker;
    var TILE = 256;
    function mercator(lon,lat,z) {
        lat = Math.max(-85.05112878,Math.min(85.05112878,lat));
        var scale = TILE * Math.pow(2,z), r=lat*Math.PI/180;
        return [(lon+180)/360*scale,(1-Math.log(Math.tan(r)+1/Math.cos(r))/Math.PI)/2*scale];
    }
    function inverse(x,y,z) {
        var scale=TILE*Math.pow(2,z), n=Math.PI*(1-2*y/scale);
        return [x/scale*360-180,180/Math.PI*Math.atan(Math.sinh(n))];
    }
    function dimensions(){return [map.clientWidth||600,map.clientHeight||420];}
    function project(p) {
        var d=dimensions(),c=mercator(state.center[0],state.center[1],state.zoom),v=mercator(p[0],p[1],state.zoom);
        return [v[0]-c[0]+d[0]/2,v[1]-c[1]+d[1]/2];
    }
    function render(){
        if (!map) return;
        var d=dimensions(),z=state.zoom,c=mercator(state.center[0],state.center[1],z);
        var left=c[0]-d[0]/2,top=c[1]-d[1]/2;
        var minX=Math.floor(left/TILE),maxX=Math.floor((left+d[0])/TILE);
        var minY=Math.floor(top/TILE),maxY=Math.floor((top+d[1])/TILE);
        var limit=Math.pow(2,z),fragment=document.createDocumentFragment();
        for(var x=minX;x<=maxX;x++)for(var y=minY;y<=maxY;y++){
            if(y<0||y>=limit)continue;
            var img=document.createElement('img');
            img.src='https://tile.openstreetmap.org/'+z+'/'+((x%limit+limit)%limit)+'/'+y+'.png';
            img.alt='';img.draggable=false;
            img.style.left=Math.round(x*TILE-left)+'px';img.style.top=Math.round(y*TILE-top)+'px';
            fragment.appendChild(img);
        }
        tiles.replaceChildren(fragment);
        overlay.setAttribute('viewBox','0 0 '+d[0]+' '+d[1]);
        route.setAttribute('d',state.points.map(function(p,i){var q=project(p);return(i?'L':'M')+q[0].toFixed(1)+' '+q[1].toFixed(1);}).join(' '));
        [[startMarker,state.start],[endMarker,state.end]].forEach(function(item){
            if(!item[1]){item[0].style.display='none';return;}
            var q=project(item[1]);item[0].style.display='';item[0].setAttribute('cx',q[0]);item[0].setAttribute('cy',q[1]);
        });
    }
    function fit(){
        if(!state.points.length)return;
        var p=state.points.concat([state.start,state.end]).filter(Boolean);
        var minLon=Math.min.apply(null,p.map(function(v){return v[0];}));
        var maxLon=Math.max.apply(null,p.map(function(v){return v[0];}));
        var minLat=Math.min.apply(null,p.map(function(v){return v[1];}));
        var maxLat=Math.max.apply(null,p.map(function(v){return v[1];}));
        state.center=[(minLon+maxLon)/2,(minLat+maxLat)/2];
        var d=dimensions();
        for(var z=17;z>=3;z--){
            var a=mercator(minLon,minLat,z),b=mercator(maxLon,maxLat,z);
            if(Math.abs(a[0]-b[0])<=d[0]-70&&Math.abs(a[1]-b[1])<=d[1]-70){state.zoom=z;break;}
        }
        render();
    }
    function collect(geom,out){
        if(!geom||!geom.coordinates)return;
        if(geom.type==='LineString')geom.coordinates.forEach(function(p){if(Array.isArray(p)&&p.length>=2&&isFinite(p[0])&&isFinite(p[1]))out.push([Number(p[0]),Number(p[1])]);});
        else if(geom.type==='MultiLineString')geom.coordinates.forEach(function(line){collect({type:'LineString',coordinates:line},out);});
    }
    window.ClearRoute=function(){
        state.points=[];state.start=null;state.end=null;
        var notice=document.getElementById('si-geo-notice');
        if(notice){notice.textContent='Розрахуйте маршрут і натисніть «Показати маршрут»';notice.style.display='';}
        render();
    };
    window.RenderRoute=function(geoJson,fromLat,fromLon,toLat,toLon){
        try{
            var data=JSON.parse(geoJson),points=[];
            if(data.type==='FeatureCollection')data.features.forEach(function(f){collect(f.geometry,points);});
            else if(data.type==='Feature')collect(data.geometry,points);
            else collect(data,points);
            if(points.length<2)throw new Error('У відповіді немає лінії маршруту');
            state.points=points;
            state.start=[Number(fromLon),Number(fromLat)];state.end=[Number(toLon),Number(toLat)];
            document.getElementById('si-geo-notice').style.display='none';
            fit();
        }catch(e){document.getElementById('si-geo-notice').textContent='Помилка геометрії: '+e.message;}
    };
    window.siGeoRouteMapInit=function(){
        map=document.getElementById('si-geo-map');tiles=document.getElementById('si-geo-tiles');overlay=document.getElementById('si-geo-overlay');
        route=document.getElementById('si-geo-route');startMarker=document.getElementById('si-geo-start');endMarker=document.getElementById('si-geo-end');
        document.getElementById('si-geo-plus').onclick=function(){state.zoom=Math.min(18,state.zoom+1);render();};
        document.getElementById('si-geo-minus').onclick=function(){state.zoom=Math.max(3,state.zoom-1);render();};
        document.getElementById('si-geo-fit').onclick=fit;
        map.addEventListener('pointerdown',function(e){if(e.target.closest('button'))return;state.drag=[e.clientX,e.clientY,state.center.slice()];map.setPointerCapture(e.pointerId);});
        map.addEventListener('pointermove',function(e){if(!state.drag)return;var c=mercator(state.drag[2][0],state.drag[2][1],state.zoom);state.center=inverse(c[0]+state.drag[0]-e.clientX,c[1]+state.drag[1]-e.clientY,state.zoom);render();});
        map.addEventListener('pointerup',function(){state.drag=null;});
        map.addEventListener('pointercancel',function(){state.drag=null;});
        map.addEventListener('wheel',function(e){e.preventDefault();state.zoom=Math.max(3,Math.min(18,state.zoom+(e.deltaY<0?1:-1)));render();},{passive:false});
        if(window.ResizeObserver)new ResizeObserver(function(){if(map && map.clientWidth && map.clientHeight)render();}).observe(map);
        render();
    };
})();
