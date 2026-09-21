import { useState, useEffect, useCallback, useRef } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T | ((val: T) => T)) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue;
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback((value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  }, [key, storedValue]);

  return [storedValue, setValue];
}

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

export function useThrottle<T>(value: T, limit: number): T {
  const [throttledValue, setThrottledValue] = useState<T>(value);
  const lastRan = useRef(Date.now());

  useEffect(() => {
    const handler = setTimeout(() => {
      if (Date.now() - lastRan.current >= limit) {
        setThrottledValue(value);
        lastRan.current = Date.now();
      }
    }, limit - (Date.now() - lastRan.current));

    return () => clearTimeout(handler);
  }, [value, limit]);

  return throttledValue;
}

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const media = window.matchMedia(query);
    if (media.matches !== matches) {
      setMatches(media.matches);
    }
    const listener = () => setMatches(media.matches);
    media.addEventListener('change', listener);
    return () => media.removeEventListener('change', listener);
  }, [matches, query]);

  return matches;
}

export function useResizeObserver<T extends Element>(
  ref: React.RefObject<T>,
  callback: (entry: ResizeObserverEntry) => void
): void {
  useEffect(() => {
    if (!ref.current) return;
    const observer = new ResizeObserver((entries) => {
      entries.forEach(callback);
    });
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [ref, callback]);
}

export function useIntersectionObserver<T extends Element>(
  ref: React.RefObject<T>,
  options: IntersectionObserverInit = {},
  callback: (entry: IntersectionObserverEntry) => void
): void {
  useEffect(() => {
    if (!ref.current) return;
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(callback);
    }, options);
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [ref, options, callback]);
}

export function useKeyPress(
  targetKey: string,
  handler: (event: KeyboardEvent) => void,
  modifiers: ('ctrl' | 'shift' | 'alt' | 'meta')[] = []
): void {
  useEffect(() => {
    const downHandler = (event: KeyboardEvent) => {
      const modifierMatch = modifiers.every((mod) => {
        switch (mod) {
          case 'ctrl': return event.ctrlKey;
          case 'shift': return event.shiftKey;
          case 'alt': return event.altKey;
          case 'meta': return event.metaKey;
          default: return false;
        }
      });

      if (event.key.toLowerCase() === targetKey.toLowerCase() && modifierMatch) {
        handler(event);
      }
    };

    window.addEventListener('keydown', downHandler);
    return () => window.removeEventListener('keydown', downHandler);
  }, [targetKey, handler, modifiers]);
}

export function useAsync<T, E = Error>(
  asyncFn: () => Promise<T>,
  deps: unknown[] = []
): { data: T | null; error: E | null; loading: boolean; execute: () => Promise<void> } {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<E | null>(null);
  const [loading, setLoading] = useState(false);

  const execute = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await asyncFn();
      setData(result);
    } catch (err) {
      setError(err as E);
    } finally {
      setLoading(false);
    }
  }, deps);

  useEffect(() => {
    execute();
  }, [execute]);

  return { data, error, loading, execute };
}

export function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
}

export function useToggle(initialValue = false): [boolean, () => void, (value: boolean) => void] {
  const [value, setValue] = useState(initialValue);
  const toggle = useCallback(() => setValue((v) => !v), []);
  const set = useCallback((v: boolean) => setValue(v), []);
  return [value, toggle, set];
}