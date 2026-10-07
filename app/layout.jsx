import '../src/styles.css'

export const metadata = {
  title: 'Nagar Shield 360 — প্রতিটি রাস্তার আরও পরিষ্কার চিত্র',
  description: 'Nagar Shield 360 শহরের দৃশ্যমান সমস্যাগুলো মানচিত্রে তুলে ধরে এবং মাঠপর্যায়ে যাচাই ও পদক্ষেপ নিতে সহায়তা করে।',
  icons: { icon: '/favicon.svg' },
}

export default function RootLayout({ children }) {
  return <html lang="bn"><body>{children}</body></html>
}
