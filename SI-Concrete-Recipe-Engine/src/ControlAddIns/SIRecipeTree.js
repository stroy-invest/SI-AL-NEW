(function () {
    'use strict';

    var host;
    var branchNodes = [];
    var selectedRow = null;

    function ensureHost() {
        if (host) return host;
        host = document.getElementById('controlAddIn') || document.body;
        host.style.fontFamily = 'Segoe UI, Arial, sans-serif';
        host.style.fontSize = '13px';
        host.style.boxSizing = 'border-box';
        host.style.height = '100%';
        host.style.overflow = 'hidden';
        return host;
    }

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text !== undefined && text !== null) n.textContent = text;
        return n;
    }

    function setSelected(row) {
        if (selectedRow) selectedRow.classList.remove('si-selected');
        selectedRow = row;
        if (selectedRow) selectedRow.classList.add('si-selected');
    }

    function toggleBranch(toggle, kids) {
        if (!kids) return;
        var open = kids.style.display === 'none';
        kids.style.display = open ? 'block' : 'none';
        toggle.textContent = open ? '▼' : '▶';
    }

    function makeNode(node, level) {
        var wrap = el('div', 'si-node-wrap');
        var row = el('div', 'si-row si-' + (node.type || '').toLowerCase());
        row.setAttribute('data-recipe-no', node.recipeNo || '');
        row.style.paddingLeft = (8 + level * 22) + 'px';

        var hasChildren = Array.isArray(node.children) && node.children.length > 0;
        var toggle = el('span', 'si-toggle', hasChildren ? '▼' : '');
        var icon = el('span', 'si-icon',
            node.type === 'Category' ? '▰' :
            node.type === 'Variant' ? '◇' : '◆');
        var name = el('span', 'si-name');
        var link = el('span', node.recipeNo ? 'si-link' : 'si-label', node.name || '');

        name.appendChild(link);
        row.appendChild(toggle);
        row.appendChild(icon);
        row.appendChild(name);

        if (node.recipeType) row.appendChild(el('span', 'si-type', node.recipeType));
        if (node.active === false) row.appendChild(el('span', 'si-badge', 'Inactive'));

        var kids = el('div', 'si-kids');
        if (hasChildren) {
            node.children.forEach(function (child) {
                kids.appendChild(makeNode(child, level + 1));
            });
            branchNodes.push({ toggle: toggle, kids: kids });
        }

        link.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            setSelected(row);
            invoke('NodeSelected', [node.type || '', node.recipeNo || '']);
            if (node.recipeNo) invoke('NodeOpen', [node.recipeNo]);
        });

        row.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            setSelected(row);
            invoke('NodeSelected', [node.type || '', node.recipeNo || '']);
            if (hasChildren) toggleBranch(toggle, kids);
        });

        row.addEventListener('dblclick', function (e) {
            e.preventDefault();
            e.stopPropagation();
            if (node.recipeNo) invoke('NodeOpen', [node.recipeNo]);
        });

        toggle.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            setSelected(row);
            invoke('NodeSelected', [node.type || '', node.recipeNo || '']);
            if (hasChildren) toggleBranch(toggle, kids);
        });

        wrap.appendChild(row);
        wrap.appendChild(kids);
        return wrap;
    }

    function render(data) {
        var root = ensureHost();
        root.innerHTML = '';
        branchNodes = [];
        selectedRow = null;

        var style = document.createElement('style');
        style.textContent =
            '.si-tree{height:100%;overflow:auto;border:1px solid #d6dce2;background:#fff;box-sizing:border-box}' +
            '.si-row{height:34px;display:flex;align-items:center;box-sizing:border-box;border-bottom:1px solid #eef0f2;cursor:pointer;user-select:none}' +
            '.si-row:hover{background:#f3f2f1}.si-selected{background:#e5f3f8!important;border-left:3px solid #008575}' +
            '.si-toggle{width:18px;flex:0 0 18px;color:#555;text-align:center}.si-icon{width:22px;flex:0 0 22px;color:#5b6770}' +
            '.si-name{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}' +
            '.si-link{color:#0066a1;text-decoration:underline;text-underline-offset:2px;cursor:pointer}' +
            '.si-label{font-weight:600}.si-category .si-label{font-weight:700;color:#323130}' +
            '.si-type{width:110px;color:#605e5c}.si-badge{margin-right:10px;padding:2px 7px;border-radius:10px;background:#f3f2f1;color:#605e5c}' +
            '.si-kids{display:block}';
        root.appendChild(style);

        var tree = el('div', 'si-tree');
        (Array.isArray(data) ? data : []).forEach(function (node) {
            tree.appendChild(makeNode(node, 0));
        });
        if (!data || !data.length)
            tree.appendChild(el('div', 'si-row', 'Немає рецептур.'));
        root.appendChild(tree);
    }

    window.RenderTree = function (treeJson) {
        var data = [];
        try { data = JSON.parse(treeJson || '[]'); } catch (e) { data = []; }
        render(data);
    };

    window.ExpandAll = function () {
        branchNodes.forEach(function (b) {
            b.kids.style.display = 'block';
            b.toggle.textContent = '▼';
        });
    };

    window.CollapseAll = function () {
        branchNodes.forEach(function (b) {
            b.kids.style.display = 'none';
            b.toggle.textContent = '▶';
        });
    };

    window.SelectRecipe = function (recipeNo) {
        if (!recipeNo) return;
        var root = ensureHost();
        var rows = root.querySelectorAll('.si-row[data-recipe-no]');
        for (var i = 0; i < rows.length; i++) {
            if (rows[i].getAttribute('data-recipe-no') === recipeNo) {
                setSelected(rows[i]);
                rows[i].scrollIntoView({ block: 'nearest' });
                return;
            }
        }
    };

    render([]);
})();
