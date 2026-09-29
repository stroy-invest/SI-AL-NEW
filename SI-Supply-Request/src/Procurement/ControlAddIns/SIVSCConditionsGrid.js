var siVscSelectedEntryNo = 0;
var siVscCurrentCategoryName = '';

function ClearGrid() {
    siVscSelectedEntryNo = 0;
    siVscCurrentCategoryName = '';
    var root = document.getElementById('controlAddIn');
    if (root) root.innerHTML = '';
}

function Render(dataJson, shipmentMethodsJson, unitsOfMeasureJson, categoryName) {
    if (siVscCurrentCategoryName !== (categoryName || ''))
        siVscSelectedEntryNo = 0;
    siVscCurrentCategoryName = categoryName || '';

    var rows = parseJson(dataJson), methods = parseJson(shipmentMethodsJson), uoms = parseJson(unitsOfMeasureJson);

    // A category owns its own rows. If the current selection does not exist in the
    // newly rendered dataset, select the only row automatically; otherwise clear it.
    if (!rows.some(function(r){ return r.entryNo === siVscSelectedEntryNo; }))
        siVscSelectedEntryNo = rows.length === 1 ? rows[0].entryNo : 0;

    var root = document.getElementById('controlAddIn');
    if (!root) return;
    root.innerHTML = '';

    var title = document.createElement('div');
    title.className = 'si-vsc-title';
    title.textContent = 'Умови постачання — ' + (categoryName || '');
    root.appendChild(title);

    var toolbar = document.createElement('div');
    toolbar.className = 'si-vsc-toolbar';
    toolbar.appendChild(button('+ Новий рядок', function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddRow', []);
    }));
    var del = button('− Видалити рядок', function () {
        if (siVscSelectedEntryNo)
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteRow', [siVscSelectedEntryNo]);
    });
    del.disabled = !siVscSelectedEntryNo || !rows.some(function(r){ return r.entryNo === siVscSelectedEntryNo; });
    toolbar.appendChild(del);
    root.appendChild(toolbar);

    if (!rows.length) {
        siVscSelectedEntryNo = 0;
        var empty = document.createElement('div');
        empty.className = 'si-vsc-empty';
        empty.textContent = 'Для цієї категорії ще немає умов постачання.';
        root.appendChild(empty);
        return;
    }

    var wrap = document.createElement('div'); wrap.className = 'si-vsc-wrap';
    var table = document.createElement('table'); table.className = 'si-vsc-table';
    table.innerHTML = '<thead><tr><th>Спосіб постачання</th><th>Мінімальна кількість замовлення</th><th>Кратність замовлення</th><th>Од. виміру</th><th>Термін постачання</th></tr></thead>';
    var body = document.createElement('tbody');

    rows.forEach(function(r) {
        var tr = document.createElement('tr');
        if (r.entryNo === siVscSelectedEntryNo) tr.className = 'si-selected';
        tr.onclick = function(){ siVscSelectedEntryNo = r.entryNo; Render(dataJson, shipmentMethodsJson, unitsOfMeasureJson, categoryName); };

        var method = select(methods, r.shipmentMethodCode, 'code', 'name'); method.className='si-vsc-method';
        var min = input('number', r.minimumOrderQuantity); min.className='si-vsc-num'; min.min='0'; min.step='any';
        var mult = input('number', r.orderMultiple); mult.className='si-vsc-num'; mult.min='0'; mult.step='any';
        var uom = select(uoms, r.uomCode, 'code', 'name'); uom.className='si-vsc-uom';
        var lead = input('text', r.leadTimeCalculation); lead.className='si-vsc-lead';

        function send() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('RowChanged', [
                r.entryNo, method.value, numberValue(min.value), numberValue(mult.value), uom.value, lead.value
            ]);
        }
        method.onchange=send; min.onchange=send; mult.onchange=send; uom.onchange=send; lead.onchange=send;
        [method,min,mult,uom,lead].forEach(function(c){
            c.autocomplete = 'off';
            c.onclick=function(e){
                e.stopPropagation();
                siVscSelectedEntryNo=r.entryNo;
                del.disabled = false;
                Array.prototype.forEach.call(body.children, function(row){ row.classList.remove('si-selected'); });
                tr.classList.add('si-selected');
            };
        });
        [method,min,mult,uom,lead].forEach(function(c){ var td=document.createElement('td'); td.appendChild(c); tr.appendChild(td); });
        body.appendChild(tr);
    });
    table.appendChild(body); wrap.appendChild(table); root.appendChild(wrap);
}
function parseJson(v){ try { return v ? JSON.parse(v) : []; } catch(e){ return []; } }
function button(text, fn){ var b=document.createElement('button'); b.type='button'; b.textContent=text; b.onclick=fn; return b; }
function input(type,value){ var i=document.createElement('input'); i.type=type; i.value=value == null ? '' : value; return i; }
function select(items,value,keyField,nameField){
    var s=document.createElement('select'), blank=document.createElement('option'); blank.value=''; blank.textContent=''; s.appendChild(blank);
    items.forEach(function(x){ var o=document.createElement('option'); o.value=x[keyField]||''; o.textContent=x[nameField]||x[keyField]||''; if(o.value===value) o.selected=true; s.appendChild(o); });
    return s;
}
function numberValue(v){ var n=parseFloat(String(v).replace(',','.')); return isNaN(n) ? 0 : n; }
