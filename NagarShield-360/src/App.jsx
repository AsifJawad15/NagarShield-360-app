'use client'

import { useState } from 'react'
import { signIn } from '../app/actions/auth'

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
  { className: 'marker-one', tone: 'amber', label: 'পানি জমেছে বলে মনে হচ্ছে' },
  { className: 'marker-two', tone: 'coral', label: 'জমে থাকা বর্জ্য' },
  { className: 'marker-three', tone: 'green', label: 'ড্রেনের মুখ' },
  { className: 'marker-four', tone: 'amber', label: 'দেখে আসার জায়গা' },
]

function MapPreview() {
  return <div className="preview-shell" aria-label="নগর পরিদর্শনের নমুনা মানচিত্র">
    <div className="preview-topbar">
      <div className="preview-dots"><i /><i /><i /></div>
      <span className="preview-title">এলাকার সারসংক্ষেপ</span>
      <span className="preview-badge">নমুনা মানচিত্র</span>
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
      <div className="map-pill"><span className="map-pill-dot" /> নমুনা এলাকা ০৪</div>
      {markers.map(marker => <span key={marker.className} className={`map-marker ${marker.className} ${marker.tone}`} title={marker.label}><span /></span>)}
      <div className="map-zoom" aria-hidden="true"><span>+</span><span>−</span></div>
      <div className="map-north">উত্তর <span>↑</span></div>
      <div className="observation-card">
        <div className="observation-icon"><Icon name="droplet" size={19} /></div>
        <div><div className="observation-label">যাচাইয়ের জন্য</div><strong>জমে থাকা পানি</strong><p>জায়গাটি দেখে নিশ্চিত হতে হবে</p></div>
        <Icon name="arrowUp" size={16} className="observation-arrow" />
      </div>
    </div>
    <div className="preview-footer"><span><i className="legend-dot amber" /> পানি</span><span><i className="legend-dot coral" /> বর্জ্য</span><span><i className="legend-dot green" /> ড্রেনের পথ</span><span className="preview-footer-right">নমুনা তথ্য</span></div>
  </div>
}

const capabilities = [
  { number: '০১', icon: 'scan', title: 'সমস্যা কোথায়, দেখুন', text: 'অনুমোদিত ছবি দেখে কোথায় পানি বা বর্জ্য জমেছে, ড্রেন বন্ধ হয়েছে কিংবা চলার পথে বাধা আছে, তা বুঝুন।' },
  { number: '০২', icon: 'layers', title: 'তথ্যগুলো একসঙ্গে দেখুন', text: 'কাছাকাছি জায়গার সমস্যাগুলো পাশাপাশি দেখুন। তাতে কোথায় আগে যেতে হবে, তা ঠিক করা সহজ হয়।' },
  { number: '০৩', icon: 'check', title: 'কাজের ফল যাচাই', text: 'কাজ দেওয়ার আগে জায়গাটি যাচাই করুন। কাজ শেষে আগের ও পরের ছবি মিলিয়ে দেখুন।' },
]

const pilotCategories = ['জমে থাকা পানি', 'ড্রেন ও পানি যাওয়ার পথ', 'জমে থাকা বর্জ্য', 'যেসব পাত্রে পানি জমে', 'রাস্তার পাশের বাধা', 'চলাচল বা ড্রেনের মুখে বাধা']

function App({ authError }) {
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
          <a href="#signin" className="nav-cta" onClick={closeMenu}>কর্মকর্তার প্রবেশ <Icon name="arrowUp" size={16} /></a>
        </nav>
        <button className="menu-toggle" type="button" aria-label={menuOpen ? 'মেনু বন্ধ করুন' : 'মেনু খুলুন'} aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}><Icon name={menuOpen ? 'close' : 'menu'} size={24} /></button>
      </div>
    </header>

    <main>
      <section className="hero container" aria-labelledby="hero-title">
        <div className="hero-copy">
          <div className="eyebrow"><span className="eyebrow-line" /> শহরের সমস্যা বুঝতে, কাজের অগ্রগতি দেখতে</div>
          <h1 id="hero-title">রাস্তার সমস্যা দেখুন,<br /><em>কাজের অগ্রগতি জানুন।</em></h1>
          <p className="hero-lede">Nagar Shield 360-এ পানি জমা, বর্জ্য ও চলাচলের বাধার মতো সমস্যা এক জায়গায় দেখা যায়। কর্মকর্তারা তথ্য যাচাই করে দায়িত্ব দিতে এবং কাজের অগ্রগতি দেখতে পারেন।</p>
          <div className="hero-actions"><a className="button button-primary" href="#approach">পদ্ধতি দেখুন <Icon name="arrow" size={18} /></a><a className="text-link" href="#pilot">পাইলটের পরিধি <Icon name="arrowUp" size={16} /></a></div>
          <div className="hero-proof"><span className="proof-icon"><Icon name="shield" size={18} /></span><span>আগে জায়গাটি যাচাই, তারপর দায়িত্ব ও কাজের ফল পর্যালোচনা।</span></div>
        </div>
        <div className="hero-visual"><div className="visual-halo" /><MapPreview /><div className="floating-note"><span className="floating-note-icon"><Icon name="spark" size={17} /></span><span>সমস্যা দেখা থেকে<br /><strong>কাজ শেষ করা</strong></span></div></div>
      </section>

      <section className="focus-strip" aria-label="পাইলটের মূলনীতি"><div className="container focus-inner"><div><span className="focus-number">০১</span><span>এলাকার সমস্যাগুলো<br />একসঙ্গে দেখুন</span></div><div><span className="focus-number">০২</span><span>চূড়ান্ত সিদ্ধান্ত<br />মানুষের হাতে</span></div><div><span className="focus-number">০৩</span><span>কাজের আগে ও পরে<br />মিলিয়ে দেখুন</span></div></div></section>

      <section id="approach" className="section approach-section"><div className="container"><div className="section-intro"><div><span className="section-kicker">আমাদের পদ্ধতি</span><h2>কোথায় আগে কাজ দরকার,<br /><em>তা এক নজরে বুঝুন।</em></h2></div><p>একই এলাকায় পানি, বর্জ্য ও ড্রেনের সমস্যা একসঙ্গে থাকতে পারে। তথ্যগুলো পাশাপাশি দেখলে কোথায় আগে যেতে হবে, তা ঠিক করা সহজ হয়।</p></div><div className="capability-grid">{capabilities.map(item => <article className="capability-card" key={item.number}><div className="card-top"><span className="card-icon"><Icon name={item.icon} size={24} /></span><span className="card-number">{item.number}</span></div><h3>{item.title}</h3><p>{item.text}</p><span className="card-rule" /></article>)}</div></div></section>

      <section id="workflow" className="workflow-section"><div className="container workflow-inner"><div className="workflow-copy"><span className="section-kicker light">কাজের ধাপ</span><h2>সমস্যা দেখুন। যাচাই করুন।<br /><em>তারপর কাজ করুন।</em></h2><p>সমস্যা শনাক্ত হওয়ার পর থেকে কাজ শেষ হওয়া পর্যন্ত কর্মকর্তারাই প্রতিটি সিদ্ধান্ত নেবেন।</p><a href="#pilot" className="button button-light">পাইলটের পরিধি দেখুন <Icon name="arrow" size={18} /></a></div><div className="workflow-steps"><div><span>০১</span><div><strong>সমস্যা চিহ্নিত করুন</strong><p>অনুমোদিত ছবিতে সমস্যা কোথায় আছে, তা মানচিত্রে দেখুন।</p></div></div><div><span>০২</span><div><strong>যাচাই ও পদক্ষেপ</strong><p>কর্মকর্তা তথ্য যাচাই করে প্রয়োজনীয় কাজের দায়িত্ব দেন।</p></div></div><div><span>০৩</span><div><strong>কাজের ফল মিলিয়ে দেখুন</strong><p>কাজের আগের ও পরের ছবি মিলিয়ে ফল যাচাই করুন।</p></div></div></div></div></section>

      <section id="pilot" className="section pilot-section"><div className="container pilot-inner"><div className="pilot-heading"><span className="section-kicker">বাংলাদেশে পরীক্ষামূলক উদ্যোগ</span><h2>শুরু হোক একটি<br /><em>ছোট এলাকা থেকে।</em></h2><p>প্রস্তাবিত ৩০০–৫০০ মিটার এলাকায় এই কাজের ধাপগুলো পরীক্ষা করে দেখা যাবে। সেখানকার অভিজ্ঞতা থেকে পদ্ধতিটি উন্নত করা যাবে।</p><div className="pilot-note"><Icon name="pin" size={18} /><span>একটি রাস্তা, বাজারের পাশের এলাকা বা ক্যাম্পাসের ভেতর</span></div></div><div className="pilot-panel"><div className="pilot-panel-head"><span>প্রাথমিক পর্যবেক্ষণ</span><span>৬টি বিষয়</span></div><div className="pilot-list">{pilotCategories.map((category, index) => <div key={category}><span className="pilot-index">{['০১', '০২', '০৩', '০৪', '০৫', '০৬'][index]}</span><span>{category}</span><Icon name="arrowUp" size={16} /></div>)}</div><p>ছবিতে সমস্যা দেখা গেলে জায়গাটি পরিদর্শন করতে হবে। কোনো সিদ্ধান্ত শুধু ছবির ওপর ভিত্তি করে নেওয়া যাবে না।</p></div></div></section>
      <section id="signin" className="signin-section"><div className="container signin-inner"><div><span className="section-kicker light">কর্মকর্তাদের ডেমো</span><h2>সমস্যা দেখা থেকে <em>কাজ শেষ করা পর্যন্ত।</em></h2><p>নমুনা ছবি দেখা, সমস্যা যাচাই, দায়িত্ব দেওয়া এবং কাজের ফল পর্যালোচনা—পুরো প্রক্রিয়াটি কর্মকর্তারা ডেমোতে দেখতে পারবেন। এখানে দেখানো তথ্য ও ফল বাস্তব নয়।</p><div className="signin-rule"><Icon name="shield" size={18}/><span>সাধারণ দর্শকরা শুধু এই পরিচিতি পাতাটি দেখতে পারবেন।</span></div></div><form action={signIn} className="signin-card"><span className="signin-card-kicker">শুধু কর্মকর্তাদের জন্য</span><h3>কর্মকর্তার সাইন ইন</h3><p>প্রশাসকের দেওয়া ডেমো অ্যাকাউন্ট দিয়ে সাইন ইন করুন। এখানে নতুন অ্যাকাউন্ট খোলার সুযোগ নেই।</p>{authError && <div className="signin-error" role="alert">{authError === 'unavailable' ? 'সার্ভারের সঙ্গে সংযোগ করা যাচ্ছে না।' : authError === 'denied' ? 'এই অ্যাকাউন্টে কর্মকর্তা হিসেবে প্রবেশের অনুমতি নেই।' : authError === 'required' ? 'এই পাতা দেখতে আগে সাইন ইন করুন।' : 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।'}</div>}<label>ইমেইল<input type="email" name="email" autoComplete="username" placeholder="name@example.gov.bd" required/></label><label>পাসওয়ার্ড<input type="password" name="password" autoComplete="current-password" placeholder="আপনার পাসওয়ার্ড" required/></label><button type="submit" className="button button-primary">সাইন ইন করুন <Icon name="arrow" size={18}/></button><small>শুধু অনুমোদিত ডেমো অ্যাকাউন্ট</small></form></div></section>
    </main>

    <footer className="site-footer"><div className="container footer-inner"><div><Logo light /><p>সমস্যা দেখা থেকে কাজের ফল যাচাই—সব এক জায়গায়.</p></div><div className="footer-right"><a href="#top">ওপরে ফিরুন ↑</a><span>© {new Date().getFullYear().toLocaleString('bn-BD', { useGrouping: false })} Nagar Shield 360</span></div></div></footer>
  </div>
}

export default App
