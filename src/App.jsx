'use client'

import { useState } from 'react'

function Icon({ name, size = 20, strokeWidth = 1.8, className = '' }) {
  const paths = {
    arrow: <><path d="M5 12h14" /><path d="m13 6 6 6-6 6" /></>,
    arrowUp: <><path d="M7 17 17 7" /><path d="M8 7h9v9" /></>,
    menu: <><path d="M4 7h16M4 12h16M4 17h16" /></>,
    close: <><path d="M5 5 19 19M19 5 5 19" /></>,
    pin: <><path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z" /><circle cx="12" cy="10" r="2.5" /></>,
    layers: <><path d="m12 3 9 5-9 5-9-5 9-5Z" /><path d="m3 12 9 5 9-5M3 16l9 5 9-5" /></>,
    scan: <><path d="M4 9V5a1 1 0 0 1 1-1h4M15 4h4a1 1 0 0 1 1 1v4M20 15v4a1 1 0 0 1-1 1h-4M9 20H5a1 1 0 0 1-1-1v-4" /><circle cx="12" cy="12" r="3" /></>,
    check: <><path d="m5 12 4 4L19 6" /></>,
    droplet: <><path d="M12 3c3.2 4.2 6 7.4 6 10.4a6 6 0 0 1-12 0C6 10.4 8.8 7.2 12 3Z" /></>,
    spark: <><path d="m12 2 1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2ZM19 17l.5 1.5L21 19l-1.5.5L19 21l-.5-1.5L17 19l1.5-.5L19 17Z" /></>,
    shield: <><path d="m12 2 8 3v6c0 5-3.2 8.5-8 11-4.8-2.5-8-6-8-11V5l8-3Z" /><path d="m8.5 12 2.5 2.5 4.5-5" /></>,
  }

  return <svg className={className} width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>
}

function Logo({ light = false }) {
  return <a className={`logo ${light ? 'logo-light' : ''}`} href="#top" aria-label="Nagar Shield 360 মূলপাতা">
    <span className="logo-mark"><Icon name="shield" size={22} strokeWidth={2.1} /></span>
    <span>Nagar Shield <span className="logo-360">360</span></span>
  </a>
}

const markers = [
  { className: 'marker-one', tone: 'amber', label: 'জমে থাকা পানির সম্ভাব্য স্থান' },
  { className: 'marker-two', tone: 'coral', label: 'দৃশ্যমান বর্জ্য' },
  { className: 'marker-three', tone: 'green', label: 'ড্রেনে প্রবেশের পথ' },
  { className: 'marker-four', tone: 'amber', label: 'পরিদর্শনের সম্ভাব্য স্থান' },
]

function MapPreview() {
  return <div className="preview-shell" aria-label="নগর পরিদর্শনের নমুনা মানচিত্র">
    <div className="preview-topbar">
      <div className="preview-dots"><i /><i /><i /></div>
      <span className="preview-title">এলাকার সারসংক্ষেপ</span>
      <span className="preview-badge">ধারণামূলক চিত্র</span>
    </div>
    <div className="map-canvas">
      <svg className="map-art" viewBox="0 0 640 490" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
        <rect width="640" height="490" fill="#e8efe8" />
        <path d="M0 15 640 0v490H0Z" fill="#eaf1e9" />
        <path d="M0 80 640 60M0 240 640 216M0 416 640 390M115 0 90 490M322 0l-19 490M535 0l-17 490" stroke="#d5e1d8" strokeWidth="2" />
        <path d="M-45 321 221 258 383 291 681 190" stroke="#d3dfd5" strokeWidth="64" fill="none" />
        <path d="M-45 321 221 258 383 291 681 190" stroke="#fffdf6" strokeWidth="48" fill="none" />
        <path d="M435-25 393 164 365 288 332 514" stroke="#d3dfd5" strokeWidth="55" fill="none" />
        <path d="M435-25 393 164 365 288 332 514" stroke="#fffdf6" strokeWidth="39" fill="none" />
        <path d="M-45 321 221 258 383 291 681 190" stroke="#e4e8de" strokeWidth="2" strokeDasharray="7 10" fill="none" />
        <path d="M435-25 393 164 365 288 332 514" stroke="#e4e8de" strokeWidth="2" strokeDasharray="7 10" fill="none" />
        <g fill="#d5e4d9" stroke="#c4d7ca" strokeWidth="2">
          <path d="m15 20 78-3-4 72-80 5z" /><path d="m142 19 142-7-5 68-142 5z" /><path d="m143 113 135-6-4 108-140 10z" />
          <path d="m20 124 73-5-7 110-67 16z" /><path d="m24 371 83-17-4 98-79 7z" /><path d="m144 345 132-27-5 129-132 7z" />
          <path d="m456 30 166-12-8 102-181 13z" /><path d="m447 156 164-10-7 56-179 29z" />
          <path d="m424 335 189-59-4 89-202 35z" /><path d="m403 425 203-33-6 84-213 8z" />
        </g>
        <g fill="#c5dacb" opacity=".75"><circle cx="118" cy="446" r="27" /><circle cx="105" cy="425" r="23" /><circle cx="287" cy="93" r="18" /><circle cx="481" cy="455" r="24" /><circle cx="537" cy="449" r="26" /></g>
        <path d="M110 313c57-16 113-47 164-51 48-4 78 27 124 24 52-4 85-35 135-56" fill="none" stroke="#469b79" strokeWidth="5" strokeLinecap="round" strokeDasharray="1 12" opacity=".9" />
        <path d="M110 313c57-16 113-47 164-51 48-4 78 27 124 24 52-4 85-35 135-56" fill="none" stroke="#8cc9a8" strokeWidth="21" strokeLinecap="round" opacity=".16" />
        <g fontFamily="Noto Sans Bengali, Nirmala UI, sans-serif" fontSize="12" fontWeight="700" fill="#8ca59a"><text x="36" y="282" transform="rotate(-13 36 282)">বাজার সড়ক</text><text x="452" y="315" transform="rotate(-18 452 315)">পাইলট এলাকা</text></g>
      </svg>
      <div className="map-grid" />
      <div className="map-pill"><span className="map-pill-dot" /> নগর সেল ০৪</div>
      {markers.map(marker => <span key={marker.className} className={`map-marker ${marker.className} ${marker.tone}`} title={marker.label}><span /></span>)}
      <div className="map-zoom" aria-hidden="true"><span>+</span><span>−</span></div>
      <div className="map-north">উত্তর <span>↑</span></div>
      <div className="observation-card">
        <div className="observation-icon"><Icon name="droplet" size={19} /></div>
        <div><div className="observation-label">যাচাইয়ের জন্য</div><strong>জমে থাকা পানি</strong><p>মাঠপর্যায়ে পরীক্ষা প্রয়োজন</p></div>
        <Icon name="arrowUp" size={16} className="observation-arrow" />
      </div>
    </div>
    <div className="preview-footer"><span><i className="legend-dot amber" /> পানি</span><span><i className="legend-dot coral" /> বর্জ্য</span><span><i className="legend-dot green" /> ড্রেনের পথ</span><span className="preview-footer-right">নমুনা তথ্য</span></div>
  </div>
}

const capabilities = [
  { number: '০১', icon: 'scan', title: 'দৃশ্যমান সমস্যা শনাক্ত', text: 'অনুমোদিত উৎসের ছবি থেকে জমে থাকা পানি, বর্জ্য, ড্রেন এবং চলাচলের বাধা এক জায়গায় দেখুন।' },
  { number: '০২', icon: 'layers', title: 'তথ্যগুলো একসঙ্গে দেখুন', text: 'কাছাকাছি পর্যবেক্ষণগুলো একই নগর সেলে যুক্ত করুন, যাতে একটি এলাকার একাধিক সমস্যা বোঝা সহজ হয়।' },
  { number: '০৩', icon: 'check', title: 'কাজের ফল যাচাই', text: 'পরিদর্শনের সম্ভাব্য স্থান চিহ্নিত করুন, মানুষের সিদ্ধান্ত নথিবদ্ধ করুন এবং কাজের আগে ও পরের তথ্য তুলনা করুন।' },
]

const pilotCategories = ['জমে থাকা পানি', 'ড্রেন ও পানিনিষ্কাশন মুখ', 'দৃশ্যমান বর্জ্য', 'পানি জমার পাত্র বা বস্তু', 'রাস্তার পাশের বাধা', 'চলাচল ও ড্রেনে প্রবেশের বাধা']

function App() {
  const [menuOpen, setMenuOpen] = useState(false)
  const closeMenu = () => setMenuOpen(false)

  return <div id="top" className="site">
    <header className="site-header">
      <div className="container header-inner">
        <Logo />
        <nav className={`main-nav ${menuOpen ? 'is-open' : ''}`} aria-label="প্রধান নেভিগেশন">
          <a href="#approach" onClick={closeMenu}>পদ্ধতি</a>
          <a href="#workflow" onClick={closeMenu}>যেভাবে কাজ করে</a>
          <a href="#pilot" onClick={closeMenu}>পাইলটের পরিধি</a>
          <a href="#pilot" className="nav-cta" onClick={closeMenu}>পাইলট দেখুন <Icon name="arrowUp" size={16} /></a>
        </nav>
        <button className="menu-toggle" type="button" aria-label={menuOpen ? 'মেনু বন্ধ করুন' : 'মেনু খুলুন'} aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}><Icon name={menuOpen ? 'close' : 'menu'} size={24} /></button>
      </div>
    </header>

    <main>
      <section className="hero container" aria-labelledby="hero-title">
        <div className="hero-copy">
          <div className="eyebrow"><span className="eyebrow-line" /> বাংলাদেশের নগর ব্যবস্থাপনার জন্য</div>
          <h1 id="hero-title">প্রতিটি রাস্তার <em>আরও পরিষ্কার চিত্র।</em></h1>
          <p className="hero-lede">Nagar Shield 360 শহরের দৃশ্যমান সমস্যাগুলো মানচিত্রে তুলে ধরে। মাঠকর্মীরা তথ্য যাচাই করে করণীয় ঠিক করতে এবং কাজের ফল দেখতে পারেন।</p>
          <div className="hero-actions"><a className="button button-primary" href="#approach">পদ্ধতি দেখুন <Icon name="arrow" size={18} /></a><a className="text-link" href="#pilot">পাইলটের পরিধি <Icon name="arrowUp" size={16} /></a></div>
          <div className="hero-proof"><span className="proof-icon"><Icon name="shield" size={18} /></span><span>মাঠপর্যায়ে যাচাই, দায়িত্বশীল পদক্ষেপ ও সুস্থ পাড়ার কথা ভেবে তৈরি।</span></div>
        </div>
        <div className="hero-visual"><div className="visual-halo" /><MapPreview /><div className="floating-note"><span className="floating-note-icon"><Icon name="spark" size={17} /></span><span>পর্যবেক্ষণ থেকে<br /><strong>পদক্ষেপে</strong></span></div></div>
      </section>

      <section className="focus-strip" aria-label="পাইলটের মূলনীতি"><div className="container focus-inner"><div><span className="focus-number">০১</span><span>নগরের পরিস্থিতি<br />একসঙ্গে দেখুন</span></div><div><span className="focus-number">০২</span><span>চূড়ান্ত সিদ্ধান্ত<br />মানুষের হাতে</span></div><div><span className="focus-number">০৩</span><span>কাজের আগে ও পরে<br />প্রমাণ দেখুন</span></div></div></section>

      <section id="approach" className="section approach-section"><div className="container"><div className="section-intro"><div><span className="section-kicker">আমাদের পদ্ধতি</span><h2>সঠিক সিদ্ধান্তের শুরু<br /><em>প্রাসঙ্গিক তথ্য থেকে।</em></h2></div><p>একটি রাস্তার সমস্যা প্রায়ই একা আসে না। একই জায়গার দৃশ্যমান তথ্যগুলো একসঙ্গে দেখে দলগুলো কোন স্থান আগে পরিদর্শন করবে, তা ঠিক করতে পারে।</p></div><div className="capability-grid">{capabilities.map(item => <article className="capability-card" key={item.number}><div className="card-top"><span className="card-icon"><Icon name={item.icon} size={24} /></span><span className="card-number">{item.number}</span></div><h3>{item.title}</h3><p>{item.text}</p><span className="card-rule" /></article>)}</div></div></section>

      <section id="workflow" className="workflow-section"><div className="container workflow-inner"><div className="workflow-copy"><span className="section-kicker light">কাজের ধাপ</span><h2>দেখুন। যাচাই করুন।<br /><em>উন্নতি আনুন।</em></h2><p>প্রথম পর্যবেক্ষণ থেকে ফল যাচাই পর্যন্ত প্রতিটি ধাপে নগর কর্তৃপক্ষের সিদ্ধান্তই মুখ্য।</p><a href="#pilot" className="button button-light">পাইলটের পরিধি দেখুন <Icon name="arrow" size={18} /></a></div><div className="workflow-steps"><div><span>০১</span><div><strong>শনাক্ত ও মানচিত্রায়ন</strong><p>অনুমোদিত ছবি সংগ্রহ করে দৃশ্যমান সমস্যার অবস্থান চিহ্নিত করুন।</p></div></div><div><span>০২</span><div><strong>যাচাই ও পদক্ষেপ</strong><p>মাঠকর্মী তথ্য যাচাই করে পরবর্তী করণীয় ঠিক করেন।</p></div></div><div><span>০৩</span><div><strong>পুনরায় দেখে ফল যাচাই</strong><p>পদক্ষেপের পরের তথ্য আগের সঙ্গে তুলনা করে ফল নথিবদ্ধ করুন।</p></div></div></div></div></section>

      <section id="pilot" className="section pilot-section"><div className="container pilot-inner"><div className="pilot-heading"><span className="section-kicker">ছোট পরিসরে শুরু, দ্রুত শেখা</span><h2>বাংলাদেশের জন্য<br /><em>সুনির্দিষ্ট পাইলট।</em></h2><p>প্রস্তাবিত ৩০০–৫০০ মিটার এলাকা কাজের ধাপ পরীক্ষা, স্থানীয় তথ্য সংগ্রহ ও পদ্ধতি উন্নত করার সুযোগ দেবে।</p><div className="pilot-note"><Icon name="pin" size={18} /><span>একটি রাস্তা, বাজারসংলগ্ন এলাকা বা ক্যাম্পাসের সীমানা</span></div></div><div className="pilot-panel"><div className="pilot-panel-head"><span>প্রাথমিক পর্যবেক্ষণ</span><span>৬টি বিষয়</span></div><div className="pilot-list">{pilotCategories.map((category, index) => <div key={category}><span className="pilot-index">{['০১', '০২', '০৩', '০৪', '০৫', '০৬'][index]}</span><span>{category}</span><Icon name="arrowUp" size={16} /></div>)}</div><p>দৃশ্যমান সমস্যাগুলো পরিদর্শনের সম্ভাব্য স্থান নির্দেশ করে। প্রতিটি সিদ্ধান্তে মানুষের যাচাই প্রয়োজন।</p></div></div></section>
    </main>

    <footer className="site-footer"><div className="container footer-inner"><div><Logo light /><p>রাস্তার তথ্য থেকে কার্যকর পদক্ষেপের পথে।</p></div><div className="footer-right"><a href="#top">ওপরে ফিরুন ↑</a><span>© {new Date().getFullYear().toLocaleString('bn-BD', { useGrouping: false })} Nagar Shield 360</span></div></div></footer>
  </div>
}

export default App
