#!/usr/bin/python
"""
Python implementation of radix-2 FFT as implemented on FPGA 
(largely accurate order-of-operations with the fft_wideband_real
"""
import numpy as np
import pdb
pi = np.pi

from fixed_point import rounding
from fixed_point import arith

# Singleton class to calculate twiddle coefficients
class twiddle_coef():
    def __getitem__(self, N):
        return np.exp(2*np.pi*1j / N)

W = twiddle_coef()

def np_error(X, X_np):
    return np.max(np.abs(X - X_np))

def delay_commutator(x, stage=1):
    """Model of delay commutator used in biplex architecture"""
    n_inputs, N = x.shape
    M = N/(2**stage)
    J = 2**stage
    data = np.zeros([n_inputs, M, J], dtype=np.complex)
    # create 3d mat of data chunks
    for k in range(J):
        data[:,:,k] = x[:, k*M:(k+1)*M]
    # turn 3d array back in to 2d
    output_data = np.zeros([2, 0], dtype=np.complex)
    for m in range(J/2):
        chunks = [data[:,:,n_inputs*m + j] for j in range(n_inputs)]
        ds = np.hstack([np.vstack([c[j,:] for c in chunks]) for j in range(n_inputs)])
        output_data = np.hstack([output_data, ds])
    return output_data

def butterfly(a, b, w):
    """Floating point radix-2 butterfly"""
    return np.array([a+b*w, a-b*w])

def butterfly_rad2_fi(a_fp, b_fp, w_fp, output_dtype=None, shift=False):
    """Fixed-point radix-2 butterfly"""
    if output_dtype == None: 
        output_dtype = a_fp.dtype

    # all data should have the same type
    assert a_fp.dtype == b_fp.dtype

    mult_dtype = (b_fp.real.intWidth + 2, b_fp.real.fractWidth + 2)
    bw_unrounded = b_fp * w_fp
    bw = rounding.round(bw_unrounded, mult_dtype, verbose=False)

    add_dtype = (mult_dtype[0] + 1, mult_dtype[1])
    apbw_fp = bw + a_fp
    ambw_fp = -bw + a_fp

    # downshift
    if shift:
        apbw_fp *= 2**-shift
        ambw_fp *= 2**-shift

    # Final cast before output
    apbw_fp = rounding.round(apbw_fp, a_fp.real.dtype, 'trunc')
    ambw_fp = rounding.round(ambw_fp, a_fp.real.dtype, 'trunc')
    of = False
    return apbw_fp, ambw_fp, of

def bit_rev(data, numbits):
    """Bit-reverse a vector of integers"""
    numbits = int(numbits)
    bit_rev_data = np.zeros(len(data))
    for k, x in enumerate(data):
        bit_rev_data[k] = sum(1<<(numbits-1-i) for i in range(numbits) if x>>i&1)
    return bit_rev_data

def get_butterfly_coeffs(fft_size, fft_stage):
    """Get the butterfly coefficients for the specified fft_size and fft_stage.
    Assumes input data is in normal order"""
    Coeffs = np.arange(2**(fft_stage-1))
    step_period = fft_size-fft_stage;    
    
    coeffs = bit_rev(Coeffs, fft_size-1)
    coeffs = np.exp(-2*np.pi*1j*coeffs/2**fft_size)
    full_coeffs = np.hstack([np.tile([c], 2**step_period) for c in coeffs])
    return coeffs, step_period, full_coeffs

def biplex_stage_n(data, stage=1):
    """N-th staget of a biplex core"""
    data_ct = delay_commutator(data, stage=stage)
    N = data.shape[1]
    coeffs, step_period, full_coeffs = get_butterfly_coeffs(np.log2(N), stage)
    full_coeffs = np.tile(full_coeffs, 2)
    stage_output = np.zeros(data.shape, dtype=np.complex)
    for k in range(N):
        stage_output[:,k] = butterfly(data_ct[0,k], data_ct[1,k], full_coeffs[k])
    return stage_output

def reorder(Z):
    """Bit-reverse the order of the biplex core output """
    N = Z.shape[1]/2
    inds = np.array(bit_rev(np.arange(N), np.log2(N)), dtype=int)
    Z1 = np.hstack([Z[0,inds], Z[1,inds]])
    Z2 = np.hstack([Z[0,inds+N], Z[1,inds+N]])
    return np.vstack([Z1, Z2])

def unscramble(Z):
    """Unscramble odd and even sub-FFTs from output of biplex core
    """
    N = len(Z)
    X_even = np.zeros(N, dtype=np.complex)
    X_odd = np.zeros(N, dtype=np.complex)
    for k in range(0, N):
        if k == 0:
            X_even[k] = 0.5*(Z[k] + np.conj(Z[0]))
            X_odd[k] = -1j*0.5*(Z[k] - np.conj(Z[0]))
        else:
            X_even[k] = 0.5*(Z[k] + np.conj(Z[N-k]))
            X_odd[k] = -1j*0.5*(Z[k] - np.conj(Z[N-k]))
    return X_even, X_odd
    #X = np.zeros(2*N, dtype=np.complex)
    #for k in range(0, N):
    #    if k == 0:
    #        X[k] = Z[k]
    #    else:
    #        twiddle = np.exp(-1j*2*pi*float(k)/(2*N))*-1j
    #        X[k] = 0.5*(Z[k] + np.conj(Z[N-k]) + twiddle*(Z[k] - np.conj(Z[N-k])))
    #return X

def biplex_cores(x_cplx):
    """Model fft_biplex_core as a series of vector-vector multiplications
    """
    X_biplex_out = np.zeros(x_cplx.shape, dtype=np.complex)
    n_streams = x_cplx.shape[0]/2
    n_stages = int(np.log2(x_cplx.shape[1]))
    for k in range(n_streams):
        X = x_cplx[2*k:2*(k+1), :]
        for m in range(n_stages):
            X = biplex_stage_n(X, stage=m+1)
        X = reorder(X)
        X_biplex_out[2*k:2*(k+1), :] = X
    return X_biplex_out

def real_fft(x, verify=False):
    """Top-level FFT function modeling the fft_wideband_real CASPER block
    """
    n_inputs = x.shape[0]
    fft_len = np.prod(x.shape)
    x_cplx = real_to_complex(x)
    n_streams = x_cplx.shape[0]
    X_biplex_output = biplex_cores(x_cplx)
    X_biplex_unscr = [unscramble(X_biplex_output[k,:]) for k in range(X_biplex_output.shape[0])]
    X_biplex_unscr = np.vstack(X_biplex_unscr)
    if verify:
        biplex_errors = [np_error(np.fft.fft(x[k,:]), X_biplex_unscr[k,:]) for k in range(n_inputs)]
        print "biplex error < %g" % max(biplex_errors)

    X_direct_input = phase_rotate(X_biplex_unscr)
    X = fft_direct(X_direct_input)
    return X.ravel()

def real_to_complex(x):
    """Re-interpret 2N real signals into N complex signals"""
    return np.vstack([x[2*k, :] + x[2*k+1, :]*1j for k in range(x.shape[0]/2)])

def phase_rotate(X_biplex_output):
    """Multiply biplex outputs by phase factors corresponding to the 
    polyphase offset between signal streams"""
    # phase factor
    n_inputs, T = X_biplex_output.shape
    N = n_inputs * T
    phase_factors = np.zeros(X_biplex_output.shape, dtype=np.complex)
    for k in range(n_inputs):
        phase_factors[k,:] = np.array([np.exp(-1j*2*pi/N*(m*k)) for m in range(T)])

    X_direct_input = X_biplex_output * phase_factors
    return X_direct_input

def fft_direct(X_direct_input):
    """Direct-form FFT, operates on columns of input independently"""
    # take the fft of each column
    n_inputs, J = X_direct_input.shape
    n_stages = int(np.log2(n_inputs))
    X_direct_output = np.zeros(X_direct_input.shape, X_direct_input.dtype)
    corner_turn_inds = np.vstack([np.arange(n_inputs), np.ones(n_inputs)*np.nan])

    remap = [None]*n_stages
    for k in range(n_stages):
        remap[k] = np.real(delay_commutator(corner_turn_inds, k+1))
        remap[k] = remap[k][:, ~np.isnan(remap[k][0,:])]

    bit_rev_inds = np.array(bit_rev(np.arange(n_inputs), n_stages), int)
    for j in range(J):
        X = X_direct_input[:,j]
        for k in range(n_stages):
            remap = np.real(delay_commutator(corner_turn_inds, k+1))
            remap = remap[:, ~np.isnan(remap[0,:])]
            _, _, stage_coeffs = get_butterfly_coeffs(n_stages, k+1)
            X_temp = np.zeros(n_inputs, X.dtype)
            for m in range(n_inputs/2):
                inds = [remap[0,m], remap[1,m]]
                X_temp[inds] = butterfly(X[inds[0]], X[inds[1]], stage_coeffs[m])

            X = X_temp.ravel()
        X_direct_output[:,j] = X[bit_rev_inds]

    X = np.vstack([np.fft.fft(X_direct_input[:,j]) for j in range(J) ]).T
    #print np.vstack([X[:,0], X_direct_output[:,0]]).T
    #return X
    return X_direct_output

if __name__ == '__main__':
    x = np.random.randn(4, 8)
    X = real_fft(x)

    X_np = np.fft.fft(x.T.ravel())
    print np_error(X, X_np)

    x = np.random.randn(4, 128)
    X = real_fft(x)
    X_np = np.fft.fft(x.T.ravel())
    print np_error(X, X_np)

    x = np.random.randn(16, 128)
    X = real_fft(x, verify=True)
    X_np = np.fft.fft(x.T.ravel())
    print np_error(X, X_np)

