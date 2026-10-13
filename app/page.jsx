import App from '../src/App.jsx'

export default async function HomePage({ searchParams }) {
  const { auth } = await searchParams
  return <App authError={auth} />
}
