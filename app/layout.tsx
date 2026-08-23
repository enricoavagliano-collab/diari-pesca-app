import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Diari di Pesca",
  description: "Companion app per i libri di Enrico Avagliano",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="it" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}

