import '../src/styles.css'

export const metadata = {
  title: 'Nagar Shield 360 — রাস্তার সমস্যা দেখুন, কাজের অগ্রগতি জানুন',
  description: 'Nagar Shield 360 শহরের সমস্যা এক জায়গায় দেখতে, যাচাই করতে এবং কাজের অগ্রগতি জানতে সহায়তা করে।',
  icons: { icon: '/favicon.svg' },
}

export default function RootLayout({ children }) {
  return <html lang="bn"><body>{children}</body></html>
}
