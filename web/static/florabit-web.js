const FlorabitWeb = (function () {
  const API = '';

  const ico = {
    dash: '<i class="fa-solid fa-table-columns fa-fw fb-fa" aria-hidden="true"></i>',
    leaf: '<i class="fa-solid fa-leaf fa-fw fb-fa" aria-hidden="true"></i>',
    book: '<i class="fa-solid fa-book fa-fw fb-fa" aria-hidden="true"></i>',
    chart: '<i class="fa-solid fa-chart-column fa-fw fb-fa" aria-hidden="true"></i>',
    info: '<i class="fa-solid fa-circle-info fa-fw fb-fa" aria-hidden="true"></i>',
    list: '<i class="fa-solid fa-list fa-fw fb-fa" aria-hidden="true"></i>',
    people: '<i class="fa-solid fa-users fa-fw fb-fa" aria-hidden="true"></i>',
    login: '<i class="fa-solid fa-right-to-bracket fa-fw fb-fa" aria-hidden="true"></i>',
    personAdd: '<i class="fa-solid fa-user-plus fa-fw fb-fa" aria-hidden="true"></i>',
    project: '<i class="fa-solid fa-seedling fa-fw fb-fa" aria-hidden="true"></i>',
    logout: '<i class="fa-solid fa-right-from-bracket fa-fw fb-fa" aria-hidden="true"></i>',
    print: '<i class="fa-solid fa-print fa-fw fb-fa" aria-hidden="true"></i>',
  };

  function navLink(href, id, activeId, label, iconHtml) {
    const cls = 'fb-nav__link' + (activeId === id ? ' is-active' : '');
    return (
      '<a href="' +
      href +
      '" class="' +
      cls +
      '">' +
      (iconHtml || '') +
      '<span>' +
      label +
      '</span></a>'
    );
  }

  async function authMe() {
    try {
      const r = await fetch(API + '/api/auth/me', { credentials: 'include' });
      return await r.json();
    } catch (e) {
      return { logged_in: false };
    }
  }

  async function requireLogin() {
    const j = await authMe();
    if (!j.logged_in) {
      window.location.href = 'login.html';
      return null;
    }
    return j;
  }

  async function requireAdmin() {
    const j = await authMe();
    if (!j.logged_in) {
      window.location.href = 'login.html';
      return null;
    }
    if (j.role !== 'admin') {
      try {
        await fetch(API + '/api/logout', { method: 'POST', credentials: 'include' });
      } catch (e) {}
      try {
        localStorage.removeItem('user');
      } catch (e) {}
      window.location.href = 'login.html';
      return null;
    }
    return j;
  }

  function attachNavToggle() {
    const btn = document.getElementById('fbNavToggle');
    if (!btn || btn.dataset.fbNavBound === '1') return;
    btn.dataset.fbNavBound = '1';
    const drawer = document.querySelector('.fb-nav__drawer');
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      const open = document.body.classList.toggle('fb-nav-open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    if (drawer) {
      drawer.addEventListener('click', function (e) {
        if (e.target.closest('a, button.fb-nav__link--ghost')) {
          document.body.classList.remove('fb-nav-open');
          btn.setAttribute('aria-expanded', 'false');
        }
      });
    }
    if (document.body.dataset.fbNavOutside !== '1') {
      document.body.dataset.fbNavOutside = '1';
      document.addEventListener('click', function (ev) {
        if (!document.body.classList.contains('fb-nav-open')) return;
        if (ev.target.closest('.fb-nav')) return;
        document.body.classList.remove('fb-nav-open');
        const t = document.getElementById('fbNavToggle');
        if (t) t.setAttribute('aria-expanded', 'false');
      });
    }
  }

  function mountGuestNav(activeId) {
    const nav = document.getElementById('fb-nav-slot');
    if (!nav) return;
    let html = '';
    html += navLink('project.html', 'project', activeId, 'نبذة عن المشروع', ico.project);
    if (activeId === 'project') {
      html += navLink('login.html', 'login', activeId, 'تسجيل دخول', ico.login);
    }
    nav.innerHTML =
      '<button type="button" class="fb-nav__toggle" id="fbNavToggle" aria-label="فتح القائمة" aria-expanded="false"><i class="fa-solid fa-bars fa-fw" aria-hidden="true"></i></button>' +
      '<div class="fb-nav__drawer">' +
      html +
      '</div>';
    nav.className = 'fb-nav fb-nav--guest';
    attachNavToggle();
  }

  function mountAppNav(activeId, me) {
    const nav = document.getElementById('fb-nav-slot');
    if (!nav || !me) return;
    let html = '';
    html += navLink('dashboard.html', 'dashboard', activeId, 'لوحة التحكم', ico.dash);
    html += navLink('plants.html', 'plants', activeId, 'النباتات', ico.leaf);
    html += navLink('plant_care_report.html', 'care_report', activeId, 'تقرير العناية', ico.print);
    html += navLink('catalog.html', 'catalog', activeId, 'الكتالوج', ico.book);
    html += navLink('reports.html', 'reports', activeId, 'التقارير', ico.chart);
    html += navLink('about.html', 'about', activeId, 'عن النظام', ico.info);
    html += navLink('care_logs.html', 'care_logs', activeId, 'سجل العناية', ico.list);
    html += navLink('users.html', 'users', activeId, 'المستخدمون', ico.people);
    html +=
      '<button type="button" class="fb-nav__link fb-nav__link--ghost" onclick="FlorabitWeb.logout()">' +
      ico.logout +
      '<span>خروج</span></button>';
    nav.innerHTML =
      '<button type="button" class="fb-nav__toggle" id="fbNavToggle" aria-label="فتح القائمة" aria-expanded="false"><i class="fa-solid fa-bars fa-fw" aria-hidden="true"></i></button>' +
      '<div class="fb-nav__drawer">' +
      html +
      '</div>';
    nav.className = 'fb-nav fb-nav--app';
    attachNavToggle();
  }

  function renderFooter() {
    const el = document.getElementById('fb-footer');
    if (!el || el.dataset.fbFooterDone === '1') return;
    el.dataset.fbFooterDone = '1';
    el.className = 'fb-footer';
    el.innerHTML =
      '<div class="fb-footer__line">فلورابيت 2026© - كل الحقوق محفوظة.</div>' +
      '<div class="fb-footer__links">' +
      '<a href="dashboard.html">لوحة التحكم</a>' +
      '<a href="plants.html">النباتات</a>' +
      '<a href="catalog.html">الكتالوج</a>' +
      '<a href="reports.html">التقارير</a>' +
      '<a href="about.html">عن النظام</a>' +
      '</div>';
  }

  function pageReady() {
    document.body.classList.add('fb-ready');
  }

  function initNav() {
    authMe().then(function (j) {
      const showAdmin = j.logged_in && j.role === 'admin';
      document.querySelectorAll('[data-admin-only]').forEach(function (el) {
        el.style.display = showAdmin ? '' : 'none';
      });
      const out = document.querySelector('[data-logout-btn]');
      if (out) {
        out.style.display = j.logged_in ? '' : 'none';
      }
    });
  }

  async function logout() {
    await fetch(API + '/api/logout', { method: 'POST', credentials: 'include' });
    try {
      localStorage.removeItem('user');
    } catch (e) {}
    window.location.href = 'login.html';
  }

  function escHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/"/g, '&quot;');
  }

  function buildCityPieGradient(rows) {
    var slice = (rows || []).slice(0, 10);
    var total = slice.reduce(function (acc, r) {
      return acc + (r.count || 0);
    }, 0);
    if (!total) {
      return { grad: '#e8e8e8', legend: '<span>لا بيانات</span>' };
    }
    var colors = [
      '#2d7a52',
      '#1565c0',
      '#ef6c00',
      '#7b1fa2',
      '#00838f',
      '#c62828',
      '#5d4037',
      '#455a64',
      '#2e7d32',
      '#ad1457',
    ];
    var cum = 0;
    var parts = [];
    var legend = [];
    slice.forEach(function (r, i) {
      var pct = ((r.count || 0) / total) * 100;
      var start = cum;
      cum += pct;
      parts.push(colors[i % colors.length] + ' ' + start + '% ' + cum + '%');
      legend.push(
        '<span><i style="background:' +
          colors[i % colors.length] +
          '"></i>' +
          escHtml(r.city) +
          ' <strong>' +
          r.count +
          '</strong></span>'
      );
    });
    return { grad: 'conic-gradient(' + parts.join(', ') + ')', legend: legend.join('') };
  }

  function renderUserAnalyticsCharts(mountEl, a) {
    if (!mountEl) return;
    if (!a) {
      mountEl.innerHTML = '<p>تعذر تحميل التحليل.</p>';
      return;
    }
    var ds = a.data_sources || {};
    var cityPie = buildCityPieGradient(a.by_city || []);
    var maxHome = Math.max.apply(
      null,
      (a.by_home_type || []).map(function (x) {
        return x.count;
      }).concat([1])
    );
    var homeRows = (a.by_home_type || [])
      .map(function (r) {
        var pct = Math.round(((r.count || 0) / maxHome) * 100);
        return (
          '<div class="fb-hbar-row"><span>' +
          escHtml(r.home_type) +
          '</span><div class="fb-hbar-track"><div class="fb-hbar-fill" style="width:' +
          pct +
          '%"></div></div><span>' +
          r.count +
          '</span></div>'
        );
      })
      .join('');
    var topList = (a.top_users_by_plant_count || []).slice(0, 10);
    var maxPlants = Math.max.apply(
      null,
      topList.map(function (x) {
        return x.plant_count;
      }).concat([1])
    );
    var topRows = topList
      .map(function (r) {
        var pct = Math.round(((r.plant_count || 0) / maxPlants) * 100);
        return (
          '<div class="fb-hbar-row"><span>' +
          escHtml(r.name) +
          '</span><div class="fb-hbar-track"><div class="fb-hbar-fill" style="width:' +
          pct +
          '%"></div></div><span>' +
          r.plant_count +
          '</span></div>'
        );
      })
      .join('');
    mountEl.innerHTML =
      '<p class="fb-analytics-summary"><strong>إجمالي المستخدمين:</strong> ' +
      escHtml(a.total_users) +
      ' — <strong>لديهم نبتة واحدة على الأقل:</strong> ' +
      escHtml(a.users_with_at_least_one_plant) +
      '</p>' +
      '<div class="fb-analytics-charts-grid">' +
      '<div class="fb-analytics-chart-card">' +
      '<h3 class="fb-analytics-chart-title">توزيع المستخدمين حسب المدينة</h3>' +
      '<div class="fb-pie-wrap"><div class="fb-pie fb-pie--analytics" style="background:' +
      cityPie.grad +
      '"></div><div class="fb-pie-legend">' +
      cityPie.legend +
      '</div></div></div>' +
      '<div class="fb-analytics-chart-card">' +
      '<h3 class="fb-analytics-chart-title">نوع السكن</h3>' +
      '<div class="fb-hbars">' +
      (homeRows || '<p class="fb-muted-p">لا بيانات.</p>') +
      '</div></div>' +
      '<div class="fb-analytics-chart-card">' +
      '<h3 class="fb-analytics-chart-title">أكثر المستخدمين نباتات</h3>' +
      '<div class="fb-hbars">' +
      (topRows || '<p class="fb-muted-p">لا بيانات.</p>') +
      '</div></div>' +
      '</div>' +
      '<dl class="fb-data-source">' +
      '<dt>من أين تأتي «المدينة» و«نوع السكن»؟</dt><dd>' +
      escHtml(ds.city_and_home || '') +
      '</dd>' +
      '<dt>عدد النباتات لكل مستخدم</dt><dd>' +
      escHtml(ds.plants_per_user || '') +
      '</dd>' +
      '<dt>سجل العناية</dt><dd>' +
      escHtml(ds.care_history || '') +
      '</dd>' +
      '<dt>الموقع الجغرافي</dt><dd>' +
      escHtml(ds.no_gps || '') +
      '</dd>' +
      '<dt>ملف القاعدة</dt><dd>' +
      escHtml(ds.database_file || '') +
      '</dd>' +
      '</dl>';
  }

  function bindTimelineExpand(root) {
    var scrollEl = root && root.querySelector ? root.querySelector('.fb-timeline-scroll') : null;
    var btn = root && root.querySelector ? root.querySelector('.fb-timeline-toggle') : null;
    if (!scrollEl || !btn) return;
    btn.addEventListener('click', function () {
      var ex = scrollEl.classList.toggle('is-expanded');
      var lab = btn.querySelector('.btn__label');
      if (lab) lab.textContent = ex ? 'طيّ' : 'عرض الكل';
      btn.setAttribute('aria-expanded', ex ? 'true' : 'false');
    });
  }

  return {
    API: API,
    authMe: authMe,
    requireLogin: requireLogin,
    requireAdmin: requireAdmin,
    initNav: initNav,
    logout: logout,
    mountGuestNav: mountGuestNav,
    mountAppNav: mountAppNav,
    renderFooter: renderFooter,
    pageReady: pageReady,
    renderUserAnalyticsCharts: renderUserAnalyticsCharts,
    bindTimelineExpand: bindTimelineExpand,
  };
})();

if (typeof window !== 'undefined') {
  window.FlorabitWeb = FlorabitWeb;
}
