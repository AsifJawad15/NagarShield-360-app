'use client'

import Link from 'next/link'
import { useState } from 'react'
import { CircleMarker, MapContainer, Polygon, Polyline, Popup, TileLayer } from 'react-leaflet'
import type { Incident } from '@/src/lib/types'

type Feature = { id:string; type:string; label_bn:string; geometry:unknown }
export default function LeafletMap({ incidents, infrastructure, onTileError }: { incidents: Incident[]; infrastructure: Feature[]; onTileError: () => void }) {
  const [failed, setFailed] = useState(false)
  const paths = infrastructure.map(item => ({...item, geometry:item.geometry as { type:string; coordinates:number[][] | number[][][] }}))
  return <MapContainer center={[23.8073,90.3688]} zoom={16} scrollWheelZoom={false} className="leaflet-demo-map">
    <TileLayer attribution="&copy; OpenStreetMap contributors · ডেমো অবস্থান" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" eventHandlers={{ tileerror: () => { if (!failed) { setFailed(true); onTileError() } } }}/>
    {paths.map(item => item.geometry.type === 'LineString' ? <Polyline key={item.id} positions={(item.geometry.coordinates as number[][]).map(([lng,lat]) => [lat,lng] as [number,number])} pathOptions={{color:item.type === 'drain' ? '#218d72' : '#d59a56',weight:5}}><Popup>{item.label_bn} · ডেমো</Popup></Polyline> : item.geometry.type === 'Polygon' ? <Polygon key={item.id} positions={(item.geometry.coordinates as number[][][])[0].map(([lng,lat]) => [lat,lng] as [number,number])} pathOptions={{color:'#3b9d7b',fillOpacity:.08}}/> : null)}
    {incidents.map(item => <CircleMarker key={item.id} center={[item.lat,item.lng]} radius={9} pathOptions={{color:'#fff',weight:2,fillColor:item.priority === 'critical' ? '#c95c4d' : item.priority === 'high' ? '#e5a250' : '#3caa81',fillOpacity:1}}><Popup><strong>{item.code} · {item.title_bn}</strong><br/><Link href={`/incidents/${item.id}`}>বিস্তারিত দেখুন →</Link></Popup></CircleMarker>)}
  </MapContainer>
}
